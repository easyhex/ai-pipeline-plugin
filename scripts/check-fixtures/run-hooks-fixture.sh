#!/usr/bin/env bash
# Behavioral contract for the enforcement hooks, executed against fixture stdin
# payloads in a scratch dir. Every case here corresponds to a real failure mode
# the v0.7 gate-2 critic demonstrated empirically.
set -eu
REPO=$(cd "$(dirname "$0")/../.." && pwd)
H="$REPO/scripts/hooks"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

die() { echo "hooks fixture FAIL: $1"; exit 1; }
payload_merge='{"tool_name":"Bash","tool_input":{"command":"git merge feature/tslug"}}'

# --- no-op guards: every hook exits 0 in a bare directory (no run, no pipeline project)
for s in post-tool-ledger pre-merge-blocker stop-verdict-gate pre-compact-snapshot prompt-context-inject; do
  printf '%s' "$payload_merge" | bash "$H/$s.sh" >/dev/null 2>&1 || die "no-op guard: $s must exit 0 outside a pipeline project"
done

mkdir -p docs/superpowers/runs docs/superpowers/critic-reports
printf '{"slug":"tslug","phase":"9"}\n' > docs/superpowers/runs/current.json

# --- pre-merge blocker
R=docs/superpowers/critic-reports/2026-01-01-tslug-gate2.md
printf '# Critic Review\n## Critical (must address before proceeding)\n- auth override logic bypassed — evidence: x\n## Important\nNone.\n' > "$R"
if printf '%s' "$payload_merge" | bash "$H/pre-merge-blocker.sh" >/dev/null 2>&1; then
  die "pre-merge: unresolved Critical (even one containing the word 'override') must block"
fi
printf '\n**Gate decision:** continue (user, 2026-01-01)\n' >> "$R"
printf '%s' "$payload_merge" | bash "$H/pre-merge-blocker.sh" >/dev/null 2>&1 \
  || die "pre-merge: a recorded 'Gate decision: continue' must unblock (decision-protocol parity)"
printf '{"tool_name":"Bash","tool_input":{"command":"git merge-base main HEAD"}}' \
  | bash "$H/pre-merge-blocker.sh" >/dev/null 2>&1 || die "pre-merge: 'git merge-base' must not match (word boundary)"
printf '{"gate":"quant","slug":"tslug","status":"failed","blocking":true}\n' > /dev/null # (verdict path tested below)
mkdir -p docs/superpowers/quant-evidence/tslug
printf '{"gate":"quant","slug":"tslug","status":"failed","blocking":true}\n' > docs/superpowers/quant-evidence/tslug/verdict.json
if printf '%s' "$payload_merge" | bash "$H/pre-merge-blocker.sh" >/dev/null 2>&1; then
  die "pre-merge: a blocking failed verdict must block the merge"
fi
rm -rf docs/superpowers/quant-evidence

# --- stop gate
if printf '{}' | bash "$H/stop-verdict-gate.sh" >/dev/null 2>&1; then
  die "stop: phase 9 with no verdict must block once"
fi
printf '{"stop_hook_active":true}' | bash "$H/stop-verdict-gate.sh" >/dev/null 2>&1 \
  || die "stop: stop_hook_active must always allow session end (loop safety)"
mkdir -p docs/superpowers/visual-evidence/tslug
printf '{"gate":"visual","slug":"tslug","status":"skipped","blocking":false}\n' > docs/superpowers/visual-evidence/tslug/verdict.json
printf '{}' | bash "$H/stop-verdict-gate.sh" >/dev/null 2>&1 \
  || die "stop: a SKIPPED verdict must satisfy the gate (gate-skip-writes-verdict)"
printf '{"slug":"tslug","phase":"7"}\n' > docs/superpowers/runs/current.json
printf '{}' | bash "$H/stop-verdict-gate.sh" >/dev/null 2>&1 || die "stop: phase 7 must not be gated"

# --- post-tool ledger appends parsable JSONL
printf '{"slug":"tslug","phase":"7"}\n' > docs/superpowers/runs/current.json
printf '%s' "$payload_merge" | bash "$H/post-tool-ledger.sh" >/dev/null 2>&1 || die "ledger: hook errored"
[ -s docs/superpowers/runs/tool-ledger.jsonl ] || die "ledger: nothing appended"
tail -1 docs/superpowers/runs/tool-ledger.jsonl | jq -e '.cmd' >/dev/null 2>&1 || die "ledger: line is not valid JSON"

echo ok
exit 0
