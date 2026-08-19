#!/usr/bin/env bash
# PostToolUse ledger — harness-recorded ground truth of Bash calls during an active
# pipeline run. The verify phase and the critic check claimed commands against this
# file instead of trusting the model's self-report.
# No-op guard: not a pipeline run in progress, or jq missing → exit 0 silently.
set -u
RUN=docs/superpowers/runs/current.json
[ -f "$RUN" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
IN=$(cat 2>/dev/null || true)
[ -n "$IN" ] || exit 0
LEDGER=docs/superpowers/runs/tool-ledger.jsonl
mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || exit 0
printf '%s' "$IN" | jq -c '{ts: (now | todate), tool: (.tool_name // ""), cmd: ((.tool_input.command // "") | .[0:200])}' >> "$LEDGER" 2>/dev/null || true
# cap ~1MB, keep the newest half
SZ=$(wc -c < "$LEDGER" 2>/dev/null | tr -d ' ' || echo 0)
if [ "${SZ:-0}" -gt 1048576 ]; then
  tail -n 2000 "$LEDGER" > "$LEDGER.tmp" 2>/dev/null && mv "$LEDGER.tmp" "$LEDGER"   # line boundary — JSONL stays parsable
fi
exit 0
