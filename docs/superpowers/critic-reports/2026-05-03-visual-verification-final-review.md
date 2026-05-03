# Critic Review — Final Review (gate-2 style) — 2026-05-03

**Subject:** v0.3.0 visual-verification feature — `git diff main..HEAD` (13 commits, 14 files, ~306 insertions)
**Reviewed against:**
- Spec: `docs/superpowers/specs/2026-05-03-visual-verification-design.md`
- Plan: `docs/superpowers/plans/2026-05-03-visual-verification.md`
- Plugin contributor doc: `CLAUDE.md`
- Hard rules 1, 5, 7, 8

---

## Critical (must address before proceeding)

None.

The implementation faithfully realises Tasks 1-13 of the plan. The visual sub-step is canonically located in `commands/feature.md` Phase 9b only (verified: `browser_navigate`/`browser_take_screenshot`/`browser_snapshot`/`browser_console_messages` appear 4× in `commands/feature.md` and 0× in `improve.md`/`fix.md` — Hard Rule 8 holds). Both manifests are at v0.3.0. JSON parses. Settings field names in `assets/templates/settings.json` (`mode`, `base_url`, `dev_command`, `dev_port_timeout_sec`, `fail_on_console_error`) match exactly the keys read via `jq` in `commands/feature.md` Phase 9b.

## Important (strongly suggest addressing)

1. **Context-layer count contradicts itself across user-facing docs.** The plan added a 6th context layer (Playwright MCP) to `assets/templates/PIPELINE.md` (line 92: "reads from 6 context layers") and to the plugin-contributor `CLAUDE.md` Hard Rule 8 ("Playwright MCP is the 6th context layer"). But:
   - `README.md:3` still says "Serena memory as a 5th context layer" — no mention of the 6th.
   - `docs/WORKFLOW_GUIDE_RU.md:3` says "5 слоёв контекста"; line 18 lists exactly 5 layers in the table; line 147 has the heading `## 5 слоёв контекста`; line 365 says "5 слоёв памяти".
   - The Russian guide's Phase 9b section was added (line 102+) but the surrounding "5 layers" prose was never bumped to 6.

   Net effect: a user reading `PIPELINE.md` sees 6 layers; a user reading the README or the Russian guide sees 5. The plan's Component-11 list said "add a section explaining the new gate" to `WORKFLOW_GUIDE_RU.md` but did not call out updating the layer count there or in the README. **Evidence:** `README.md:3`, `docs/WORKFLOW_GUIDE_RU.md:3, 18, 147, 365` vs. `assets/templates/PIPELINE.md:92` and `CLAUDE.md:23`. **Fix:** bump "5" → "6" in those four locations and add a Playwright row to the Russian context-layer table at line 151-157.

2. **`6-command` / `7-command` drift.** Task 12 bumped both manifests to "7-command", and `assets/templates/CLAUDE.md` already uses "7" via the user-facing command table. But several user-visible strings still say "6":
   - `assets/templates/CLAUDE.md:3` — "This project uses a 6-command AI development pipeline." (line 1 of the file users get from `/init`).
   - `assets/templates/PIPELINE.md:3` — "describes the 6-command AI development pipeline".
   - `README.md:90` — "pipeline rules and the 6-command surface".
   - `commands/init.md:297` — the first commit message body says `Pipeline: ai-pipeline plugin v0.1.0 (6-command AI development pipeline)`. Both the version (v0.1.0) and the count (6) are stale; the user's git history will record this. **Evidence:** `grep -n "6-command" …`. **Fix:** mass-replace `6-command` → `7-command` in those four locations and bump the literal `v0.1.0` in `commands/init.md:297` to `v0.3.0` (or remove the version literal — better, since it requires manual maintenance per release).

3. **`assets/templates/settings.json` SessionStart hook still lists 6 commands.** Line 8 echoes `Pipeline: /init /plan-improve /feature /improve /fix /lesson` — missing `/remember` (added in v0.2.0). The Russian workflow guide lines 275 already shows the intended 7-command echo (`… /lesson /remember`) but the actual template that ships to users does not. The v0.3.0 PR is a clean opportunity to fix this v0.2.0 carryover. **Evidence:** `assets/templates/settings.json:8` vs. `docs/WORKFLOW_GUIDE_RU.md:275`. **Fix:** append `/remember` to the echo string.

4. **Shell-injection surface, mitigation needed in command file.** Phase 9b spawns `bash -c "$DEV_CMD"` with `DEV_CMD` either:
   - the literal `npm run dev` / `npm run start` (safe), or
   - the `dev_command` setting straight from `.claude/settings.json` (under user control).
   Since the user controls the settings file, this is not an attacker-controlled vector; it is design-acknowledged in the spec. Two issues:
   (a) The trap string `trap "[ -n \"$DEV_PID\" ] && kill $DEV_PID 2>/dev/null" EXIT` uses double quotes so `$DEV_PID` is **expanded at trap-set time**, not at trap-fire time. At set-time `DEV_PID` is just-assigned so this happens to work, but if a future edit moves the trap before `DEV_PID=$!` it will silently kill nothing. Use single quotes around the whole trap body to defer expansion: `trap '[ -n "$DEV_PID" ] && kill "$DEV_PID" 2>/dev/null' EXIT`. **Evidence:** `commands/feature.md:288`.
   (b) The trap kills the process on script exit but the very next thing the snippet does on a non-`required` failure is set `SKIP_VISUAL=yes` and fall through to Phase 10, leaving the trap armed. If the slash-command runner doesn't re-enter a fresh shell for Phase 10, a later `kill $DEV_PID` of an empty/stale PID is harmless but the trap text references a `$DEV_PID` that may have been overwritten or unset by a subsequent shell. Suggest: explicitly `trap - EXIT` after the cleanup-block at the end of Phase 9b, or move the trap into a sub-shell that wraps the whole sub-step.

5. **Backslash-escape consistency in the console-error grep.** Line 380 reads:
   ```bash
   grep -qiE "\\[error\\]|console\\.error|TypeError|ReferenceError" "$EVIDENCE_DIR/console.txt"
   ```
   Inside double quotes, `\\[` is two characters (`\`, `[`); `grep -E` then sees `\[`, which matches a literal `[` — correct. Same for `\\.` → `\.`. Result is correct, but the double-escaping is fragile: if a future edit converts the string to a heredoc or single-quoted, `\\[` becomes a literal backslash-bracket, and the regex breaks silently. Suggest single-quoting the pattern: `grep -qiE '\[error\]|console\.error|TypeError|ReferenceError' …`. **Evidence:** `commands/feature.md:380`.

6. **`URLS` is multi-line; bash `for path in $URLS` works because of word-splitting, but `echo $URLS | tr '\n' ' '` in the heredoc emits an unquoted variable that bash splits on whitespace before echo even runs.** Functionally equivalent here, but if a URL ever contains a `?` or `&` (it shouldn't — they're stripped) the rendering in `summary.md` will be wrong. Quoting `"$URLS"` and switching to `printf '%s\n' "$URLS" | tr '\n' ' '` would be more robust. **Evidence:** `commands/feature.md:392`. Low-impact, edge case only.

7. **`exit 1` inside a slash-command bash block.** Lines 262, 282, 301, 379 use `exit 1` to abort. In a Claude-Code-driven `/feature` orchestration, the slash-command runner does not actually fork a single shell that captures `exit 1` at the orchestrator level — each block is a separate Bash tool call. `exit 1` will return a non-zero status from that tool call but the orchestrator (the LLM running the command file) has to honour the "STOP" instruction in prose. The bash `exit` is essentially advisory. This is consistent with the rest of the plugin's command files (e.g. `commands/init.md` uses the same pattern at line 201), so not a regression — but worth noting that the **prose** "[ "$MODE" = "required" ] && exit 1" must be paired with explicit pipeline-stop instructions in the surrounding markdown for the LLM to actually halt. The current text at lines 411-415 ("Apply verdict: VERDICT=FAIL and MODE=required → STOP …") does this correctly. Just flagging the pattern so a future edit doesn't drop the prose and rely solely on `exit 1`.

## Nice to have

1. **`/improve` Phase 9 inheritance line and `/fix` Phase 7 line both reference `## URLs to verify`, but only `feature.md` Phase 2 has the brainstorm hint that tells the brainstormer to add the section.** `improve.md:54` says "The brainstorm in Phase 2 must include `## URLs to verify`". `fix.md:87` says "the spec at `<SLUG>-diagnosis.md` should include a `## URLs to verify` section". Neither command file actually adds a corresponding hint to its own Phase 2. Result: the visual gate may run without a `URLs to verify` section in the spec, which the URL extractor handles gracefully (falls back to `/`), so this is a doc/UX nit, not a defect. Either add a parallel "Frontend hint" block to `improve.md` and `fix.md` Phase 2, or trim the inheritance lines to "if the spec has `## URLs to verify`, those are visited; else `/`".

2. **`feature.md:23` announce string says "11 phases"** but Phase 9 now has a sub-step 9b. Cosmetic; could read "11 phases (with optional 9b visual sub-step for frontend projects)".

3. **`commands/init.md:297`** — already covered as Important #2, but additionally the commit-message line is stale on every release; consider deriving the version from `${TEMPLATE_DIR}/../plugin.json` or just removing the version literal entirely.

4. **`docs/superpowers/critic-reports/`** is referenced in `commands/feature.md:100` and `agents/senior-critic.md:61` as a report destination, but it isn't on the list created by `/init` Phase 3. Looking at `commands/init.md:210`, the directories made are `.claude/lessons docs/superpowers/specs docs/superpowers/plans docs/superpowers/critic-reports docs-meta .claude` — actually the reports dir IS created. Disregard this nit. (Verified during review by `mkdir -p` in the worktree, which then succeeded silently — the dir is in the `/init` script.)

5. **`agents/senior-critic.md` Visual drift bullet says "URLs declared in spec's `## URLs to verify` but not visited (per `summary.md`'s `URLs visited` line)"**, but the summary template emits `URLs visited: $(echo $URLS | tr '\n' ' ')` — i.e. the URLs that **were** visited, not a comparison. The critic then has to do the diff itself by reading both the spec and the summary. That's fine but worth flagging in the critic doc that the comparison logic is the critic's, not pre-computed.

6. **macOS/Linux compatibility.** `stat -f%z … || stat -c%s …` (line 369) is the correct portable idiom. `date -Iseconds 2>/dev/null || date` (line 389) is also portable. `seq 1 $TIMEOUT` (line 290) is fine on both. `awk … sed -E … grep -E …` (lines 312-313) all portable. Good.

## Lessons applied

None matched the trigger of any lesson — the plugin repo has no `.claude/lessons/` files (only the per-project template ships the directory).

## Lessons NOT applied (and why)

None — see above.

## Memories to capture (suggested)

- `visual-gate-canonical-location`: The visual sub-step is canonical only in `commands/feature.md` Phase 9b; `commands/improve.md` and `commands/fix.md` reference it textually and do NOT duplicate the bash/MCP block. Hard Rule 8 in the plugin contributor `CLAUDE.md` enforces this — any future visual-gate edit must touch `feature.md` only. — This is a stable structural decision worth surfacing to future agents who might "helpfully" sync the block across commands.
- `command-count-and-context-layer-count-drift-risk`: Whenever a new command (e.g. `/remember` in v0.2.0) or new context layer (e.g. Playwright MCP in v0.3.0) is added, six places need bumping in lockstep: `README.md`, `README_RU.md`, `assets/templates/CLAUDE.md`, `assets/templates/PIPELINE.md`, `docs/WORKFLOW_GUIDE_RU.md`, and the `assets/templates/settings.json` SessionStart echo. The current PR drift in the layer count and command count proves this list belongs in a checklist that agents follow on every minor bump. — Stable convention; should be a memory or a hard rule in `CLAUDE.md`.

---

## Summary

13/13 implementation tasks complete and faithful to the plan. Architecture is clean: the bash/MCP block lives in exactly one file, the settings schema is canonical, the version bump is consistent across both manifests, and the critic now reads visual evidence at gate-2 without breaking the existing output contract.

Six **Important** findings cluster around documentation drift introduced by partial updates: the "5 layers" / "6 layers" inconsistency, the "6-command" / "7-command" inconsistency, and a stale `/remember` omission in the SessionStart hook. None block the v0.3.0 release on functional grounds, but they will confuse users reading the wrong doc first. Strongly recommend folding a "doc-sync" task into the smoke-test (Task 14) before tagging.

Two trap/escape robustness suggestions in the bash block (Important #4-5) are defensive: the current code works but is fragile against future edits.
