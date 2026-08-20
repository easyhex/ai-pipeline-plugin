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
src = open('scripts/pipeline/visual-verdict.sh').read()
m = re.search(r"FC=\$\(jq -r '([^']+)'", src)
if not m:
    print("fail_on_console_error jq line not found in visual-verdict.sh"); sys.exit(1)
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
   && grep -qF '## URLs to verify' scripts/pipeline/visual-preflight.sh \
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
if grep -qF 'index.html ] && [ -f package.json' scripts/pipeline/detect-frontend.sh \
   && ! grep -rq '^\[ -f index.html \] && HAS_FRONTEND=yes$' commands/ scripts/pipeline/; then
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

# T19 — coverage-tree templates ship (generic + numerics) and are referenced.
if [ -f assets/templates/ELICITATION_TREES.md ] \
   && grep -q 'ELICITATION_TREES' assets/templates/ELICITATION.md \
   && grep -q 'ELICITATION_TREES' commands/init.md; then
  pass "T19 coverage-tree templates ship and are referenced"
else fail "T19 coverage-tree templates missing (spec A2)"; fi

# T20 — PIPELINE.md may not contradict the playback gate: no walk-away promise,
# no 3-question /init description.
if grep -q 'walks away' assets/templates/PIPELINE.md || grep -q '~3 clarifying questions' assets/templates/PIPELINE.md; then
  fail "T20 PIPELINE.md still promises walk-away autonomy / 3-question init (contradicts Phase 3.5)"
else pass "T20 PIPELINE.md consistent with the playback gate"; fi

# T21 — /fix defines its own (light) playback: diagnosis approval recorded.
if grep -q 'Approved by user' commands/fix.md; then
  pass "T21 /fix plays back the diagnosis and records approval"
else fail "T21 /fix playback undefined (rule 8 claims /fix inherits the gate)"; fi

# T22 — /plan-improve clears '(proposed — unconfirmed)' tags.
if grep -q 'proposed — unconfirmed' commands/plan-improve.md; then
  pass "T22 /plan-improve clears unconfirmed-proposal tags"
else fail "T22 '(proposed — unconfirmed)' tags are never cleared by any command"; fi

# T23 — /init's stakes answer persists: default_weight stored and read back.
if grep -q 'default_weight' assets/templates/settings.json \
   && grep -q 'default_weight' commands/init.md \
   && grep -q 'default_weight' commands/feature.md; then
  pass "T23 default ceremony weight persisted and read by /feature"
else fail "T23 stakes answer is a dead data path (default weight stored nowhere)"; fi

# T24 — post-sign-off open decisions have a defined route.
if grep -q 'After sign-off' commands/feature.md && grep -qi 'post-approval' assets/templates/ELICITATION.md; then
  pass "T24 post-approval decision route defined"
else fail "T24 mid-build open decisions have no defined route (autonomy vs no-silent-decisions)"; fi

# T25 — gate-1 critic audits spec provenance sections.
if grep -q 'User decisions' agents/senior-critic.md; then
  pass "T25 critic gate-1 provenance audit present"
else fail "T25 provenance sections exist but no gate audits them"; fi

# T26 — the Phase 4 pre-condition (the playback gate's teeth) is present verbatim.
if grep -qF 'must contain an `**Approved by user:**` line' commands/feature.md; then
  pass "T26 Phase 4 approval pre-condition present"
else fail "T26 Phase 4 no longer enforces the playback approval"; fi

# ---- v0.5 requirements contract ----

# T27 — SPEC_FORMAT.md is the single home of the spec schema + EARS grammar:
# all five named patterns must be present.
if [ -f assets/templates/SPEC_FORMAT.md ] \
   && grep -q 'SHALL' assets/templates/SPEC_FORMAT.md \
   && grep -q 'Ubiquitous' assets/templates/SPEC_FORMAT.md \
   && grep -q 'Event-driven' assets/templates/SPEC_FORMAT.md \
   && grep -q 'State-driven' assets/templates/SPEC_FORMAT.md \
   && grep -q 'Optional feature' assets/templates/SPEC_FORMAT.md \
   && grep -q 'Unwanted behaviour' assets/templates/SPEC_FORMAT.md \
   && grep -q 'SPEC_FORMAT' commands/feature.md \
   && grep -q 'EARS' agents/senior-critic.md; then
  pass "T27 SPEC_FORMAT + all five EARS patterns shipped, referenced, critic-enforced"
else fail "T27 SPEC_FORMAT/EARS missing, incomplete, or unenforced"; fi

# T28 — living requirement files: format ships, feature.md creates them with mid uuids,
# improve.md amends them, and the [F-XXX] placeholder is gone.
if [ -f assets/templates/REQUIREMENTS_FORMAT.md ] \
   && grep -q 'mid:' assets/templates/REQUIREMENTS_FORMAT.md \
   && grep -q 'REQUIREMENTS_FORMAT' commands/feature.md \
   && grep -q 'REQUIREMENTS_FORMAT\|docs/requirements/F-' commands/improve.md \
   && ! grep -q 'F-XXX' commands/feature.md; then
  pass "T28 living requirement files with mid identity; F-XXX placeholder gone"
else fail "T28 requirements files missing, unminted, or F-XXX placeholder survives"; fi

# T29 — risk register: template ships, EVERY gate's override appends a row
# (feature gate-1, gate-2 via 'same protocol', plan-improve), ground+critic read it.
if [ -f assets/templates/risks.md ] \
   && [ "$(grep -c 'append a.*`docs/risks.md`\|append a `docs/risks.md` row' commands/feature.md)" -ge 2 ] \
   && grep -q 'append a `docs/risks.md` row' commands/plan-improve.md \
   && grep -q 'risks.md' agents/senior-critic.md; then
  pass "T29 risk register wired into all overrides, ground, and critic"
else fail "T29 an override path still bypasses docs/risks.md"; fi

# T30 — /release ships: CHANGELOG, mid-diff, local tag, no push.
if [ -f commands/release.md ] && grep -q 'CHANGELOG' commands/release.md \
   && grep -q 'mid' commands/release.md \
   && grep -qi 'do NOT push\|never push' commands/release.md; then
  pass "T30 /release with CHANGELOG + mid-diff + no-push"
else fail "T30 /release missing or incomplete"; fi

# T31 — traceability: Phase 11 appends a TRACEABILITY.md row.
if grep -q 'TRACEABILITY' commands/feature.md; then
  pass "T31 traceability row appended at Phase 11"
else fail "T31 no traceability join (requirement→spec→gates→SHA)"; fi

# T32 — glossary + analogs templates ship and are read in ground.
if [ -f assets/templates/glossary.md ] && [ -f assets/templates/analogs.md ] \
   && grep -q 'glossary' commands/feature.md && grep -q 'analogs' commands/feature.md \
   && grep -q 'analogs' commands/init.md; then
  pass "T32 glossary + analogs shipped and grounded"
else fail "T32 glossary/analogs missing or never read"; fi

# T33 — ADRs: format ships; critic marks [decision]; orchestrator writes docs/decisions/.
if [ -f assets/templates/ADR_FORMAT.md ] \
   && grep -q '\[decision\]' agents/senior-critic.md \
   && grep -q 'docs/decisions/' commands/feature.md; then
  pass "T33 ADR pipeline (critic marks, orchestrator writes)"
else fail "T33 decision rationale still uncommitted (no ADR path)"; fi

# T35 — /improve defines its Phase 3.5 delta: the amend path must NOT re-mint.
if grep -q 'Phase 3.5' commands/improve.md && grep -qi 'do NOT mint\|no new F-ID\|without minting' commands/improve.md; then
  pass "T35 /improve amend path does not re-mint F-IDs"
else fail "T35 /improve inherits the unconditional mint — duplicate requirements files"; fi

# T36 — /release: first-release behavior defined, mid collection is global (rename-proof).
if grep -qi 'first release' commands/release.md && grep -qi 'ls-tree\|ALL files under\|all mids' commands/release.md; then
  pass "T36 /release handles first release + global mid-diff"
else fail "T36 /release mid-diff is per-path or first-release undefined"; fi

# T37 — mint uniqueness scans beyond features.md (requirements/ + TRACEABILITY).
if grep -qF 'across `docs/features.md`, `docs/requirements/`' commands/feature.md; then
  pass "T37 F-ID mint scans features.md + requirements/ + traceability"
else fail "T37 F-ID uniqueness derived from features.md alone (double-mint risk)"; fi

# T38 — the approved spec + requirements file are committed at Phase 3.5 (worktree-visible, no orphans).
if grep -qi 'commit.*approv\|approv.*commit' commands/feature.md; then
  pass "T38 approval is committed at Phase 3.5"
else fail "T38 requirements file stays untracked until Phase 11"; fi

# T34 — Master Plan docs are versioned: doc_version in all four templates, bumped by /plan-improve.
if grep -q 'doc_version' assets/templates/architecture.md \
   && grep -q 'doc_version' assets/templates/features.md \
   && grep -q 'doc_version' assets/templates/roadmap.md \
   && grep -q 'doc_version' assets/templates/risks.md 2>/dev/null \
   && grep -q 'doc_version' commands/plan-improve.md; then
  pass "T34 Master Plan docs carry versions + change history"
else fail "T34 Master Plan docs still mutate without version headers"; fi

# ---- v0.6 math contract ----

# T39 — NUMERICS_TESTING.md: all five oracle types + named tolerance stop condition.
if [ -f assets/templates/NUMERICS_TESTING.md ] \
   && grep -qi 'analytic' assets/templates/NUMERICS_TESTING.md \
   && grep -qi 'manufactured' assets/templates/NUMERICS_TESTING.md \
   && grep -qi 'metamorphic\|property' assets/templates/NUMERICS_TESTING.md \
   && grep -qi 'reference implementation' assets/templates/NUMERICS_TESTING.md \
   && grep -qi 'convergence' assets/templates/NUMERICS_TESTING.md \
   && grep -qi 'tolerance chosen to make the test pass' assets/templates/NUMERICS_TESTING.md \
   && grep -q 'NUMERICS_TESTING' commands/feature.md; then
  pass "T39 oracle taxonomy shipped and referenced"
else fail "T39 NUMERICS_TESTING.md missing, incomplete, or unreferenced"; fi

# T40 — quant_verify settings schema: in settings.json AND reflected in both templates
# (rule: settings schema is source of truth); 9c canonical only in feature.md.
if grep -q 'quant_verify' assets/templates/settings.json \
   && grep -q 'quant_verify' assets/templates/CLAUDE.md \
   && grep -q 'quant_verify' assets/templates/PIPELINE.md \
   && [ "$(grep -l 'quant-verify.sh' commands/*.md | wc -l | tr -d ' ')" = "1" ]; then
  pass "T40 quant_verify schema reflected everywhere; 9c gate canonical in feature.md"
else fail "T40 quant_verify schema drift or 9c gate duplicated"; fi

# T41 — 9c honesty semantics: run-manifest, pass^k, anti-overclaim downgrade.
if grep -q 'run-manifest' commands/feature.md \
   && grep -q 'pass^k' commands/feature.md \
   && grep -qi 'partial' commands/feature.md; then
  pass "T41 run-manifest + pass^k + verified/partial downgrade present"
else fail "T41 quant gate can overclaim (no manifest/pass^k/partial semantics)"; fi

# T42 — numeric critic: typed severities + claims quarantine + sabotage check.
if grep -qi 'float equality\|exact float' agents/senior-critic.md \
   && grep -qi 'tolerance fraud' agents/senior-critic.md \
   && grep -qi 'testimony, not evidence\|without the spec' agents/senior-critic.md \
   && grep -qi 'sabotage\|weaken.*tolerance\|deleted.*test' agents/senior-critic.md \
   && grep -qi 'which check fails\|which test fails' agents/senior-critic.md; then
  pass "T42 numeric critic checklist + quarantine + gap lens + sabotage check"
else fail "T42 critic still blind to numerical failure modes"; fi

# T43 — requirements schema: verify-method enum, @relation markers, suspect hashes.
if grep -q 'Test | Analysis | Inspection | Review' assets/templates/REQUIREMENTS_FORMAT.md \
   && grep -q '@relation' assets/templates/REQUIREMENTS_FORMAT.md \
   && grep -qi 'suspect' assets/templates/REQUIREMENTS_FORMAT.md; then
  pass "T43 verify-method enum + code markers + suspect links in schema"
else fail "T43 requirements schema lacks verification-method/code-link fields"; fi

# T44 — project class: asked at /init, stored, drives defaults; model.md ships AND is
# wired (plan-improve owns it, ground reads it) — template-only shipping is a defect.
if grep -q 'project_class' commands/init.md \
   && grep -q 'project_class' assets/templates/settings.json \
   && [ -f assets/templates/model.md ] \
   && grep -q 'model.md' commands/init.md \
   && grep -q 'model.md' commands/plan-improve.md \
   && [ "$(grep -c 'model.md' commands/feature.md)" -ge 2 ]; then
  pass "T44 project class stored + model.md owned and ground-read"
else fail "T44 project class missing or model.md is write-only after /init"; fi

# T45 — numeric specs must carry Mathematical approach + Interface contracts (gate-1 Critical).
if grep -q 'Mathematical approach' assets/templates/SPEC_FORMAT.md \
   && grep -q 'Interface contracts' assets/templates/SPEC_FORMAT.md \
   && grep -q 'Mathematical approach' agents/senior-critic.md \
   && grep -q 'Interface contracts' agents/senior-critic.md; then
  pass "T45 math sections mandated and critic-enforced (both)"
else fail "T45 numeric specs can still omit the mathematics"; fi

# T47 — no 9b skip path may bypass 9c: the only 'skip to Phase 10' left is 9c's own.
if [ "$(grep -c 'skip to Phase 10' commands/feature.md)" -le 1 ] \
   && ! grep -q 'skip directly to Phase 10' commands/feature.md \
   && [ "$(grep -c 'go directly to Phase 9c\|go to Phase 9c' commands/feature.md)" -ge 2 ]; then
  pass "T47 all pre-9c skip paths route through 9c"
else fail "T47 a 9b skip path jumps straight to Phase 10 — compute projects bypass the quant gate"; fi

# T48 — verdict honesty: zero-checks branch + mutation threshold defined + dead-end routed.
if grep -qi 'zero collected checks' commands/feature.md \
   && grep -q 'mutation_threshold' assets/templates/settings.json \
   && grep -q 'mutation_threshold' commands/feature.md \
   && grep -qi '9c' commands/feature.md && grep -A2 -i 'partial.*/.*failed.*required\|failed.*+ .QMODE=required' commands/feature.md | grep -qi 'address\|override' ; then
  pass "T48 no vacuous verified; mutation threshold real; 9c failure has an address route"
else fail "T48 9c can overclaim on empty checks / phantom threshold / dead-end failure"; fi

# T46 — inheritance deltas: /improve and /fix explicitly define their 9c behavior.
if grep -q '9c' commands/improve.md && grep -q '9c' commands/fix.md; then
  pass "T46 /improve and /fix carry explicit 9c deltas"
else fail "T46 9c inherited without deltas (inheritance-delta-checklist violation)"; fi

# ---- v0.7 mechanism contract ----

# T49 — plugin hooks: hooks.json exists, every referenced script exists, parses (bash -n),
# and carries a no-op guard so non-pipeline projects are unaffected.
if [ -f hooks/hooks.json ] && jq empty hooks/hooks.json 2>/dev/null; then
  HOOKS_OK=yes
  for s in $(jq -r '.. | .command? // empty' hooks/hooks.json | grep -o 'scripts/hooks/[a-z-]*\.sh'); do
    [ -f "$s" ] && bash -n "$s" 2>/dev/null && grep -q 'exit 0' "$s" || { HOOKS_OK=no; echo "  bad hook: $s"; }
  done
  [ "$HOOKS_OK" = "yes" ] && pass "T49 plugin hooks present, parse, and guard no-op" \
    || fail "T49 a hook script is missing, unparsable, or unguarded"
else fail "T49 hooks/hooks.json missing or invalid"; fi

# T50 — Stop hook loop safety: must honor stop_hook_active (never an unclosable session).
if grep -q 'stop_hook_active' scripts/hooks/stop-verdict-gate.sh 2>/dev/null; then
  pass "T50 Stop hook blocks at most once"
else fail "T50 Stop hook can loop a session shut"; fi

# T58 — hooks BEHAVE per contract (fixture-executed stdin payloads): decision-protocol
# parity, word-boundary matching, skip-verdict satisfaction, loop safety, ledger JSONL.
if bash scripts/check-fixtures/run-hooks-fixture.sh >/dev/null 2>&1; then
  pass "T58 hook fixtures: blocker parity, stop gate, ledger — all behave"
else fail "T58 a hook violates its behavioral contract (run scripts/check-fixtures/run-hooks-fixture.sh)"; fi

# T51 — pipeline bash lives in scripts, not markdown: every scripts/pipeline/*.sh parses,
# feature.md calls them, and the old inline dev-server block is gone from feature.md.
if ls scripts/pipeline/*.sh >/dev/null 2>&1; then
  P_OK=yes
  for s in scripts/pipeline/*.sh; do bash -n "$s" 2>/dev/null || { P_OK=no; echo "  syntax: $s"; }; done
  if [ "$P_OK" = "yes" ] && grep -q 'visual-preflight.sh' commands/feature.md \
     && grep -q 'quant-verify.sh' commands/feature.md \
     && ! grep -q 'DEV_PID=\$!' commands/feature.md; then
    pass "T51 pipeline bash decomposed into tested scripts"
  else fail "T51 scripts unparsable or feature.md still carries inline gate bash"; fi
else fail "T51 scripts/pipeline/ missing"; fi

# T52 — quant-verify.sh honors the vacuous-verdict guard and pass^k (fixture-executed).
if [ -f scripts/pipeline/quant-verify.sh ] && bash scripts/check-fixtures/run-quant-fixture.sh >/dev/null 2>&1; then
  pass "T52 quant-verify fixture: zero checks in required → partial; failing seed → failed"
else fail "T52 quant-verify script missing or fixture contract broken"; fi

# T53 — critic report ends with a machine verdict block; commands parse it.
if grep -q 'Machine verdict' agents/senior-critic.md \
   && grep -q '"status": "concerns"' agents/senior-critic.md \
   && grep -q 'status: concerns' commands/feature.md; then
  pass "T53 machine-readable critic verdict + orchestrator branch"
else fail "T53 gate outcomes still prose-only"; fi

# T54 — /resume ships (10th command), derives phase from artifacts, not just the cache.
if [ -f commands/resume.md ] && grep -qi 'derive\|artifact' commands/resume.md \
   && grep -q 'runs/current.json' commands/resume.md \
   && grep -q 'runs/current.json' commands/feature.md; then
  pass "T54 /resume + run-state cache updated by /feature"
else fail "T54 pipeline runs still die with the session"; fi

# T55 — playwright pinned (no @latest anywhere in commands/).
if grep -rq '@playwright/mcp@latest' commands/ assets/; then
  fail "T55 @playwright/mcp still unpinned"
else grep -rq '@playwright/mcp@0' commands/init.md && pass "T55 playwright MCP version pinned" \
  || fail "T55 playwright registration missing a pinned version"; fi

# T56 — layer-status banner: script exists and is wired into ground + final report.
if [ -f scripts/pipeline/layer-status.sh ] && [ "$(grep -c 'layer-status' commands/feature.md)" -ge 2 ]; then
  pass "T56 layer-status probed at ground and reported at finish"
else fail "T56 six-layer degradation still silent"; fi

# T57 — promptfoo skeleton: config + fixture project + scenario for the playback halt.
if [ -f tests/promptfoo/promptfooconfig.yaml ] && [ -d tests/promptfoo/fixtures/miniproj ] \
   && grep -qi 'playback\|Approved by user' tests/promptfoo/promptfooconfig.yaml; then
  pass "T57 promptfoo behavioral skeleton present"
else fail "T57 no behavioral CI skeleton"; fi

# ---- v1.0 validation-loop contract ----

# T59 — success criteria are first-class and /validate closes the reality loop.
if grep -q 'Success criteria' assets/templates/SPEC_FORMAT.md \
   && grep -q 'Success criteria' assets/templates/REQUIREMENTS_FORMAT.md \
   && [ -f commands/validate.md ] \
   && grep -q 'unchecked' commands/validate.md \
   && grep -q 'plan-improve' commands/validate.md; then
  pass "T59 success criteria + /validate outcome loop"
else fail "T59 shipped features are never validated against reality"; fi

# T60 — /deprecate: impact scan, migration plan, intended-break signal to the critic.
if [ -f commands/deprecate.md ] \
   && grep -q 'migration' commands/deprecate.md \
   && grep -q 'TRACEABILITY' commands/deprecate.md \
   && grep -qi 'intended\|deliberate' commands/deprecate.md \
   && grep -q 'BREAKING' commands/deprecate.md; then
  pass "T60 /deprecate with migration plan and intended-break protocol"
else fail "T60 non-additive change (deprecation/breaking) still inexpressible"; fi

# T61 — lesson distillation: cursor, DISTILLED.md, ground reads compiled rules first.
if grep -q 'distill' commands/lesson.md \
   && grep -q 'lesson-cursor' commands/lesson.md \
   && grep -q 'DISTILLED' commands/lesson.md \
   && grep -q 'DISTILLED' commands/feature.md \
   && grep -q 'DISTILLED' commands/fix.md; then
  pass "T61 lessons compile into rules (cursor + DISTILLED.md, ground-read)"
else fail "T61 lessons still accumulate linearly with no distillation"; fi

# T62 — fresh-context verification: a critic mode, dispatched before findings reach the user.
if grep -qi 'verification mode' agents/senior-critic.md \
   && grep -qi 'evidence, not instructions\|evidence-not-instructions' agents/senior-critic.md \
   && grep -qi 'verification mode\|fresh-context' commands/feature.md; then
  pass "T62 fresh-context finding verification wired at gate-2"
else fail "T62 unreproduced critic findings still reach the user"; fi

# T63 — out-of-scope KB: template ships, playback writes it, gate-1 critic reads it.
if [ -f assets/templates/out-of-scope.md ] \
   && grep -q 'out-of-scope' commands/feature.md \
   && grep -q 'out-of-scope' commands/init.md \
   && grep -q 'out-of-scope' agents/senior-critic.md \
   && grep -q 'out-of-scope' commands/plan-improve.md; then
  pass "T63 deliberate refusals persist (out-of-scope KB)"
else fail "T63 rejected concepts get re-litigated forever"; fi

# ---- v1.1 adopt contract ----

# T64 — the Master Plan pre-flight must read a MISSING architecture.md as unfilled
# (executed: extract the actual check line from feature.md, run it in an empty dir).
if python3 - <<'EOF'
import re, subprocess, sys, tempfile, os
src = open('commands/feature.md', encoding='utf-8').read()
m = re.search(r'Run: `([^`]*UNFILLED[^`]*)`', src)
if not m:
    print("pre-flight check line not found"); sys.exit(1)
check = m.group(1).replace('\\"', '"')
with tempfile.TemporaryDirectory() as d:
    out = subprocess.run(['bash', '-c', check], cwd=d, capture_output=True, text=True).stdout.strip()
    if out != 'unfilled':
        print(f"empty dir gives {out!r}, want 'unfilled'"); sys.exit(1)
    os.makedirs(os.path.join(d, 'docs')); open(os.path.join(d, 'docs/architecture.md'), 'w').write('# A\nfilled content')
    out = subprocess.run(['bash', '-c', check], cwd=d, capture_output=True, text=True).stdout.strip()
    if out != 'filled':
        print(f"filled doc gives {out!r}, want 'filled'"); sys.exit(1)
sys.exit(0)
EOF
then pass "T64 missing Master Plan reads as unfilled (executed)"
else fail "T64 a repo with no docs at all passes the Master Plan pre-flight"; fi
if ! grep -rqF '&& echo unfilled || echo filled' commands/ \
   && [ "$(grep -rlF 'echo filled || echo unfilled' commands/ | wc -l | tr -d ' ')" = "3" ]; then
  pass "T64b corrected pre-flight in all three literal carriers; inverted form extinct"
else fail "T64b an inverted Master Plan pre-flight survives in a command file"; fi

# T65 — /init adopt path: existing codebases are onboarded, never clobbered.
if grep -qi 'adopt' commands/init.md \
   && grep -qi 'reverse-engineer\|derived from the ACTUAL code\|from the actual code' commands/init.md \
   && grep -qi 'never overwrite\|do not overwrite\|append.*gitignore\|gitignore.*append' commands/init.md \
   && grep -q 'proposed — unconfirmed' commands/init.md; then
  pass "T65 /init adopts existing codebases (derive, confirm, never overwrite)"
else fail "T65 existing codebases still have no onboarding path"; fi

echo
if [ "$FAILS" -gt 0 ]; then echo "$FAILS test(s) failed"; exit 1; fi
echo "all green"
