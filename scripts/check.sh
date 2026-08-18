#!/usr/bin/env bash
# Contract tests for the ai-pipeline plugin repo.
# Run from repo root before every version bump: bash scripts/check.sh
# Exit 0 = all green. Each failed test prints FAIL and the reason.

set -u
cd "$(dirname "$0")/.."
FAILS=0

fail() { echo "FAIL: $1"; FAILS=$((FAILS+1)); }
pass() { echo "  ok: $1"; }

# T1 — the fail_on_console_error jq filter must honor an explicit `false`.
# Executes the actual filter extracted from feature.md against two fixtures.
if python3 - <<'EOF'
import re, json, subprocess, sys
src = open('commands/feature.md').read()
m = re.search(r"FAIL_CONSOLE=\$\(jq -r '([^']+)'", src)
if not m:
    print("FAIL_CONSOLE jq line not found in feature.md"); sys.exit(1)
filt = m.group(1)
cases = [
    ({"pipeline": {"visual_verify": {"fail_on_console_error": False}}}, "false"),
    ({}, "true"),
]
for fixture, expected in cases:
    out = subprocess.run(["jq", "-r", filt], input=json.dumps(fixture),
                         capture_output=True, text=True).stdout.strip()
    if out != expected:
        print(f"filter {filt!r} gives {out!r} for {fixture}, want {expected!r}")
        sys.exit(1)
sys.exit(0)
EOF
then pass "T1 fail_on_console_error=false is honored"
else fail "T1 fail_on_console_error off-switch is dead (jq // treats false as absent)"; fi

# T2 — Phase 9b spec path must be a SPEC_FILE parameter, and /fix must set it
# to its diagnosis file (otherwise /fix never extracts URLs).
if grep -q 'SPEC_FILE' commands/feature.md && grep -q 'SPEC_FILE' commands/fix.md; then
  pass "T2 visual-verify spec path is parameterized (SPEC_FILE in feature.md + fix.md)"
else fail "T2 Phase 9b hardcodes the /feature spec path; /fix diagnosis URLs are never read"; fi

# T3 — beads IDs are project-prefixed; nothing may assume a 'bd-' prefix.
if grep -q "bd-\[0-9\]" commands/*.md; then
  fail "T3 EPIC_ID capture assumes a 'bd-' issue prefix beads does not guarantee"
else pass "T3 no hardcoded beads ID prefix"; fi
if grep -q 'bd create -t epic .*--silent' commands/feature.md; then
  pass "T3b epic ID captured via bd create --silent"
else fail "T3b feature.md does not use 'bd create --silent' for the epic ID"; fi

# T4 — command-count drift: the count lives in assets/templates/PIPELINE.md only.
if grep -rqE '6[- ](command|slash)' CLAUDE.md docs/DESIGN_NOTES.md .claude-plugin/marketplace.json 2>/dev/null; then
  fail "T4 stale '6 commands' still asserted outside the canonical count"
else pass "T4 no stale command counts"; fi
V_PLUGIN=$(jq -r '.version' .claude-plugin/plugin.json)
V_MARKET=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)
if [ "$V_PLUGIN" = "$V_MARKET" ]; then pass "T4b plugin.json and marketplace.json versions agree ($V_PLUGIN)"
else fail "T4b version drift: plugin.json=$V_PLUGIN marketplace.json=$V_MARKET"; fi

# T5 — no push mandate: the repo forbids git push from inside Claude (CLAUDE.md rule 6).
# beads may regenerate AGENTS.md; this catches the mandate coming back.
if grep -qiE 'PUSH TO REMOTE|NEVER stop before pushing|until .?git push.? succeeds' AGENTS.md 2>/dev/null; then
  fail "T5 AGENTS.md mandates git push, contradicting CLAUDE.md rule 6"
else pass "T5 AGENTS.md has no push mandate"; fi

# T6 — no phantom paths: commands/agents ship in the plugin cache, never in user projects.
if grep -rq '\.claude/commands/\|\.claude/agents/' commands/ assets/templates/PIPELINE.md 2>/dev/null; then
  fail "T6 reference to .claude/commands|agents/ — those paths do not exist in user projects"
else pass "T6 no phantom .claude/commands|agents paths"; fi

# T7 — a bare index.html must not force the visual gate on compute repos.
if grep -q '^\[ -f index.html \] && HAS_FRONTEND=yes$' commands/feature.md; then
  fail "T7 unconditional '[ -f index.html ]' frontend detection hard-blocks compute repos"
else pass "T7 index.html detection is conditional"; fi

# T8 — all shipped JSON parses.
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json assets/templates/settings.json; do
  if jq empty "$f" 2>/dev/null; then pass "T8 $f is valid JSON"
  else fail "T8 $f is not valid JSON"; fi
done

# T9 — contributor rule 8: the visual-verify Playwright block is canonical in feature.md only.
N=$(grep -l 'browser_navigate' commands/*.md | wc -l | tr -d ' ')
if [ "$N" = "1" ] && grep -q 'browser_navigate' commands/feature.md; then
  pass "T9 visual-verify MCP block lives only in feature.md"
else fail "T9 visual-verify MCP block duplicated or missing (found in $N command files)"; fi

echo
if [ "$FAILS" -gt 0 ]; then echo "$FAILS test(s) failed"; exit 1; fi
echo "all green"
