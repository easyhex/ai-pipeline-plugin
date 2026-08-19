#!/usr/bin/env bash
# PreToolUse gate — during an active pipeline run, block `git merge` / `git push` /
# `gh pr create` while a blocking gate verdict stands or Critical findings are
# unresolved without an override. Exit 2 blocks the tool call; the message reaches
# the model. No-op guard: no active run / jq missing → exit 0.
set -u
RUN=docs/superpowers/runs/current.json
[ -f "$RUN" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
IN=$(cat 2>/dev/null || true)
[ -n "$IN" ] || exit 0
CMD=$(printf '%s' "$IN" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
printf '%s' "$CMD" | grep -qE 'git (merge|push)( |$)|gh pr create' || exit 0
SLUG=$(jq -r '.slug // ""' "$RUN" 2>/dev/null || echo "")
[ -n "$SLUG" ] || exit 0

block() { echo "ai-pipeline gate: $1" >&2; exit 2; }

for G in visual quant; do
  V="docs/superpowers/${G}-evidence/${SLUG}/verdict.json"
  if [ -f "$V" ]; then
    S=$(jq -r '.status // "unknown"' "$V" 2>/dev/null || echo unknown)
    B=$(jq -r '.blocking // false' "$V" 2>/dev/null || echo false)
    if [ "$B" = "true" ]; then
      case "$S" in
        pass|verified) : ;;
        *) block "the $G gate verdict for '$SLUG' is '$S' — address the findings or override (docs/risks.md row) before merging" ;;
      esac
    fi
  fi
done

R=$(ls -t docs/superpowers/critic-reports/*"${SLUG}"*.md 2>/dev/null | head -1 || true)
if [ -n "$R" ] && [ -f "$R" ]; then
  CRIT=$(awk '/^## Critical/{f=1; next} /^## /{f=0} f && /^- /' "$R" | head -1)
  # Resolution = an ANCHORED decision record the orchestrator appends on continue/override
  # ("**Gate decision:** ..."). A finding merely containing the word "override" resolves nothing.
  if [ -n "$CRIT" ] && ! grep -q '^\*\*Gate decision:\*\*' "$R"; then
    block "unresolved Critical finding in $(basename "$R") — decide continue/address/override; the decision is recorded in the report as '**Gate decision:** ...'"
  fi
fi
exit 0
