#!/usr/bin/env bash
# Stop gate — while a pipeline run sits in the verify phases (9/9b/9c/10) with no gate
# verdict written, block session end ONCE with directions. stop_hook_active loop
# safety: if we already blocked, always let the session end (never an unclosable
# session). No-op guard: no active run → exit 0.
set -u
IN=$(cat 2>/dev/null || true)
RUN=docs/superpowers/runs/current.json
[ -f "$RUN" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
ACTIVE=$(printf '%s' "$IN" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)
[ "$ACTIVE" = "true" ] && exit 0
PHASE=$(jq -r '.phase // ""' "$RUN" 2>/dev/null || echo "")
SLUG=$(jq -r '.slug // ""' "$RUN" 2>/dev/null || echo "")
case "$PHASE" in
  9|9b|9c|10) : ;;
  *) exit 0 ;;
esac
for G in visual quant; do
  [ -f "docs/superpowers/${G}-evidence/${SLUG}/verdict.json" ] && exit 0
done
echo "ai-pipeline: run '$SLUG' is at phase $PHASE with no gate verdict written. Finish the verify phase (write the verdict), or abandon the run by deleting docs/superpowers/runs/current.json." >&2
exit 2
