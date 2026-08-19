#!/usr/bin/env bash
# UserPromptSubmit injection — in pipeline projects, mechanically inject a compact
# digest (lessons index, memory names, active-run position) into every prompt,
# instead of trusting the model to run its Phase-1 reads. stdout becomes context.
# No-op guard: not a pipeline project → exit 0 with no output.
set -u
[ -f docs-meta/PIPELINE.md ] || exit 0
OUT=""
if ls .claude/lessons/*.md >/dev/null 2>&1; then
  N=$(ls .claude/lessons/*.md 2>/dev/null | wc -l | tr -d ' ')
  TRIGGERS=$(grep -h '^trigger:' .claude/lessons/*.md 2>/dev/null | head -12 | sed 's/^trigger: */• /' | tr '\n' ' ')
  OUT="Lessons (${N}): ${TRIGGERS}"
fi
if [ -d .serena/memories ]; then
  MEMS=$(ls .serena/memories 2>/dev/null | sed 's/\.md$//' | head -15 | tr '\n' ' ')
  [ -n "$MEMS" ] && OUT="${OUT}
Memories: ${MEMS}"
fi
if [ -f docs/superpowers/runs/current.json ] && command -v jq >/dev/null 2>&1; then
  LINE=$(jq -r '"run \(.slug // "?") — phase \(.phase // "?")"' docs/superpowers/runs/current.json 2>/dev/null || echo "")
  [ -n "$LINE" ] && OUT="${OUT}
Active: ${LINE}"
fi
[ -n "$OUT" ] && printf '[ai-pipeline context]\n%s\n' "$OUT"
exit 0
