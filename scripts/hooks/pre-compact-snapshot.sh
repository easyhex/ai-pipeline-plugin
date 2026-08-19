#!/usr/bin/env bash
# PreCompact snapshot — preserve the run position and the ledger tail at the moment
# context is about to be destroyed, so /resume has fresh material after compaction.
# No-op guard: no active run → exit 0. Never blocks (always exit 0).
set -u
RUN=docs/superpowers/runs/current.json
[ -f "$RUN" ] || exit 0
D=docs/superpowers/runs
cp "$RUN" "$D/precompact-snapshot.json" 2>/dev/null || true
if [ -f "$D/tool-ledger.jsonl" ]; then
  tail -n 50 "$D/tool-ledger.jsonl" > "$D/precompact-ledger-tail.jsonl" 2>/dev/null || true
fi
exit 0
