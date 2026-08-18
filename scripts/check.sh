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

# T2 — Phase 9b must resolve SPEC_FILE statelessly INSIDE the extraction block
# (bash blocks may run as separate shells — no cross-command variable handoff),
# prefer the /fix diagnosis file, and the awk must consume the variable.
if grep -qF -- '-diagnosis.md" ] && SPEC_FILE=' commands/feature.md \
   && grep -qF '"$SPEC_FILE" | sed' commands/feature.md \
   && ! grep -qF 'docs/superpowers/specs/<SLUG>.md | sed' commands/feature.md \
   && grep -qF -- '-diagnosis.md' commands/fix.md; then
  pass "T2 SPEC_FILE resolved statelessly at extraction, diagnosis file preferred"
else fail "T2 Phase 9b spec-file resolution is hardcoded or relies on cross-shell state"; fi

# T3 — beads IDs are project-prefixed; nothing may assume a 'bd-' prefix.
if grep -rq "bd-\[0-9\]" commands/ agents/ assets/ 2>/dev/null; then
  fail "T3 EPIC_ID capture assumes a 'bd-' issue prefix beads does not guarantee"
else pass "T3 no hardcoded beads ID prefix"; fi
if grep -q 'bd create -t epic .*--silent' commands/feature.md; then
  pass "T3b epic ID captured via bd create --silent"
else fail "T3b feature.md does not use 'bd create --silent' for the epic ID"; fi

# T4 — every restated command count must equal the real number of files in commands/.
# This checks the INVARIANT, not a stale literal: adding an 8th command turns every
# remaining "7-command" claim into a failure.
if python3 - <<'EOF'
import re, glob, sys
n = len(glob.glob('commands/*.md'))
files = ['README.md', 'README_RU.md', 'CLAUDE.md', 'docs/DESIGN_NOTES.md',
         'assets/templates/CLAUDE.md', 'assets/templates/PIPELINE.md',
         'commands/init.md', '.claude-plugin/plugin.json', '.claude-plugin/marketplace.json']
bad = []
for f in files:
    txt = open(f, encoding='utf-8').read()
    for m in re.finditer(r'(\d+)[- ](?:user-facing )?(?:command|slash command|команд)', txt):
        if int(m.group(1)) != n:
            bad.append(f"{f}: '{m.group(0)}' but commands/ holds {n} files")
if bad:
    print('\n'.join(bad))
sys.exit(1 if bad else 0)
EOF
then pass "T4 all restated command counts match commands/ file count"
else fail "T4 a restated command count disagrees with the actual commands/ inventory"; fi
V_PLUGIN=$(jq -r '.version' .claude-plugin/plugin.json)
V_MARKET=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)
if [ "$V_PLUGIN" = "$V_MARKET" ]; then pass "T4b plugin.json and marketplace.json versions agree ($V_PLUGIN)"
else fail "T4b version drift: plugin.json=$V_PLUGIN marketplace.json=$V_MARKET"; fi

# T5 — no push mandate: the repo forbids git push from inside Claude (CLAUDE.md rule 6).
# beads may regenerate AGENTS.md; this catches the mandate coming back.
if grep -qiE 'PUSH TO REMOTE|NEVER stop before pushing|until .?git push.? succeeds' AGENTS.md 2>/dev/null; then
  fail "T5 AGENTS.md mandates git push, contradicting CLAUDE.md rule 6"
else pass "T5 AGENTS.md has no push mandate"; fi
# T5b — the authoritative no-push policy must live OUTSIDE the beads-managed marker
# block, so a beads regeneration of the block cannot silently delete it.
if awk '/END BEADS INTEGRATION/{f=1; next} f' AGENTS.md 2>/dev/null | grep -q 'No `git push`'; then
  pass "T5b authoritative git policy survives outside the beads-managed block"
else fail "T5b no-push policy missing outside the beads marker block (regen would erase it)"; fi

# T6 — no phantom paths: commands/agents ship in the plugin cache, never in user projects.
if grep -rq '\.claude/commands/\|\.claude/agents/' commands/ assets/templates/PIPELINE.md 2>/dev/null; then
  fail "T6 reference to .claude/commands|agents/ — those paths do not exist in user projects"
else pass "T6 no phantom .claude/commands|agents paths"; fi

# T7 — a bare index.html must not force the visual gate on compute repos:
# the index.html rule must be guarded by package.json (positive invariant),
# and the old unconditional line must be gone.
if grep -qF 'index.html ] && [ -f package.json' commands/feature.md \
   && ! grep -q '^\[ -f index.html \] && HAS_FRONTEND=yes$' commands/feature.md; then
  pass "T7 index.html detection requires package.json alongside"
else fail "T7 index.html frontend detection is unconditional (hard-blocks compute repos)"; fi

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

# ---- v0.4 elicitation contract ----

# T10 — ELICITATION.md is the single source of the interview technique: it exists,
# every elicitation-running command references it, and its "Question hygiene"
# section is never duplicated into a command file.
if [ -f assets/templates/ELICITATION.md ] \
   && grep -q 'ELICITATION.md' commands/feature.md \
   && grep -q 'ELICITATION.md' commands/init.md \
   && grep -q 'ELICITATION.md' commands/plan-improve.md \
   && grep -q 'ELICITATION.md' commands/questionnaire.md \
   && [ "$(grep -rl 'Question hygiene' commands/ assets/ 2>/dev/null | wc -l | tr -d ' ')" = "1" ]; then
  pass "T10 ELICITATION.md canonical and referenced by all four commands"
else fail "T10 elicitation primitive missing, unreferenced, or duplicated"; fi

# T11 — the anti-elicitation reflex is gone.
if grep -rqi 'proceed silently' commands/; then
  fail "T11 'proceed silently' still present in a command file"
else pass "T11 no 'proceed silently' in commands"; fi

# T12 — playback gate exists, declares the planning-boundary rule, records approval.
if grep -q 'Phase 3.5' commands/feature.md && grep -q 'authorizes planning only' commands/feature.md \
   && grep -q 'Approved by user' commands/feature.md; then
  pass "T12 playback gate with planning-boundary and approval record"
else fail "T12 playback gate missing planning-boundary or approval record"; fi

# T13 — spec provenance sections are mandated.
if grep -q 'User decisions (verbatim)' commands/feature.md \
   && grep -q 'Assumptions (machine, unconfirmed)' commands/feature.md \
   && grep -q 'Out of scope (confirmed)' commands/feature.md; then
  pass "T13 provenance sections mandated in the spec contract"
else fail "T13 spec provenance sections not mandated"; fi

# T14 — the unimplementable reply-timeout is gone; gate decisions are synchronous.
if grep -rq '1 message exchange' commands/ assets/ 2>/dev/null; then
  fail "T14 fictitious reply-timeout still present"
else pass "T14 no fictitious gate timeout"; fi

# T15 — Important-only critic outcome has defined behavior at both gates.
if grep -q 'Important-only' commands/feature.md && grep -q 'Important-only' assets/templates/PIPELINE.md; then
  pass "T15 Important-only gate outcome defined"
else fail "T15 Important-only critic outcome undefined"; fi

# T16 — /init confirms machine-drafted plans line-by-line before committing.
if grep -q 'proposed — unconfirmed' commands/init.md && grep -q 'BEFORE the first commit' commands/init.md; then
  pass "T16 /init line-by-line confirmation gate present"
else fail "T16 /init still commits machine-invented plans unreviewed"; fi

# T17 — ceremony weight exists and is recorded in the spec frontmatter.
if grep -qE 'weight: (light \| standard \| deep|light\|standard\|deep)' commands/feature.md \
   && grep -q 'weight' assets/templates/ELICITATION.md 2>/dev/null; then
  pass "T17 ceremony weight defined and recorded in spec"
else fail "T17 ceremony weight missing"; fi

# T18 — /questionnaire ships, writes to docs/requirements/, and ground reads answers back.
if [ -f commands/questionnaire.md ] && grep -q 'docs/requirements/' commands/questionnaire.md \
   && grep -q 'questionnaire' commands/feature.md; then
  pass "T18 /questionnaire command + ground-phase return path"
else fail "T18 /questionnaire missing or no return path in ground"; fi

echo
if [ "$FAILS" -gt 0 ]; then echo "$FAILS test(s) failed"; exit 1; fi
echo "all green"
