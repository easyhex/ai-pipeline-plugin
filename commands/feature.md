---
description: Build new functionality end-to-end. Interviews to shared understanding (frontier rounds per docs-meta/ELICITATION.md), critic-reviewed spec, explicit playback sign-off — then autonomous plan → TDD → critic → verify → finish.
argument-hint: "<feature description>"
---

# /feature — build new functionality (interview → sign-off → autonomous)

**Input:** `$ARGUMENTS` (the feature description)

## Pre-flight

1. **Master Plan must exist:**
   - Run: `grep -q "UNFILLED" docs/architecture.md 2>/dev/null && echo unfilled || echo filled`
   - If `unfilled` → STOP. Print: "Run `/init \"<app description>\"` first."

2. **Generate slug:**
   - Take first 4-6 meaningful words from `$ARGUMENTS`
   - Convert to lowercase, hyphenate
   - Format: `YYYY-MM-DD-<slug>` (use today's date)
   - Save as `$SLUG` for use in filenames throughout

3. **Run-state:** if `docs/superpowers/runs/current.json` exists → STOP: "run '<its slug>' is in flight — `/resume` it or delete the file to abandon." Otherwise create it:
   ```bash
   mkdir -p docs/superpowers/runs
   printf '{"slug":"<SLUG>","phase":"1","started":"%s"}\n' "$(date -Iseconds 2>/dev/null || date)" > docs/superpowers/runs/current.json
   ```
   Update `.phase` and `.updated` (ISO date) at EVERY phase boundary (`jq '.phase="<N>"' … > tmp && mv`); Phase 3.5 adds `.f_id`, `.approvals.spec=true`; Phase 6 adds `.branch`; Phase 11 deletes the file (run complete). This cache powers `/resume` and the plugin's enforcement hooks — but artifacts on disk remain the truth.

4. **Announce intent:**
   - Tell the user: "Starting /feature pipeline for: <description>. Slug: <SLUG>. I'll interview you until we share an understanding of what to build, play the spec back for your sign-off, then run autonomously through plan → TDD → critic → verify → finish. After sign-off I'll only stop when the critic surfaces findings that need your decision, or on failures."

---

## Phase 1: Ground

Read in full:
- `docs/architecture.md`
- `docs/features.md`
- `docs/roadmap.md`
- `docs-meta/DISTILLED.md` (if it exists) FIRST — compiled lesson rules; then only raw lessons newer than `docs-meta/.lesson-cursor` (the undistilled tail); no cursor → every file under `.claude/lessons/`
- `docs/analysis/out-of-scope.md` — deliberate refusals; do not re-propose a recorded concept without addressing its reason
- `docs/model.md` (when it exists — compute classes): the mathematical ground truth this feature must respect (assumptions, invariants, accuracy targets)
- `docs/glossary.md` (use its terms; a term used contrary to the glossary is a defect)
- `docs/risks.md` — note every `open` risk whose scope plausibly matches this work
- `docs/analysis/analogs.md` — what existing solutions prove right or wrong here
- Relevant living requirement files under `docs/requirements/F-*.md` (features this work touches)
- Answered questionnaires under `docs/requirements/questionnaire-*.md` (if any) — a questionnaire counts as answered when its answer stubs (`> Ответ:` / `> Answer:` lines) are non-empty; answered ones are user decisions with provenance, carry them into the spec's "User decisions" section

Detect libraries from package manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, etc.). For each detected library that is *plausibly relevant* to this feature, query Context7:

```
mcp__plugin_context7-plugin_context7__resolve-library-id { libraryName: "<lib>" }
mcp__plugin_context7-plugin_context7__query-docs { id: "<resolved>", topic: "<topic relevant to feature>" }
```

**Memory grounding (NEW):**

Call `mcp__serena__list_memories` to retrieve all memory names. For each name whose slug substring-matches the feature description (`$ARGUMENTS`) OR matches files plausibly affected by this work, call `mcp__serena__read_memory({ name: <name> })` and incorporate its content into your context.

Add a `Memory grounding: N memories loaded (<comma-separated names>)` line to the internal ground summary. If `list_memories` fails (Serena MCP not running), skip this step silently with one note: `Memory grounding: skipped (Serena unavailable)`.

Close the ground phase with the six-layer health banner — print its one line to the user (degradation stays allowed, but visible):

```bash
PIPE="$(ls -d "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline"/*/ 2>/dev/null | sort -V | tail -1)scripts/pipeline"
bash "$PIPE/layer-status.sh"
```

Produce a 5-10 bullet **ground summary** (internal — not shown to user unless asked):
- Architecture context (where this feature fits)
- Existing features it interacts with
- Roadmap position
- Lessons that match this feature's domain (cite filenames)
- Library-specific gotchas from Context7
- Memory grounding results (N memories loaded, or skipped)
- Open questions for brainstorm

---

## Phase 2: Interview + brainstorm

Invoke `superpowers:brainstorming` with:
- The user's feature description
- The ground summary as context

**Elicitation contract** (canonical: `docs-meta/ELICITATION.md` — follow it, do not improvise a different interview):

- Facts are your job — look them up; never ask the user what the environment can answer.
- Every open decision goes to the user as a numbered frontier round (❓ N + ➡️ Recommended) and you WAIT. No cap on questions; the bound is by kind, not count.
- Confirm each substantive answer with a one-sentence paraphrase before treating it as settled.
- The first round includes the ceremony-weight question (`weight: light | standard | deep`); its ➡️ recommendation is the project default from `jq -r '.pipeline.default_weight // "standard"' .claude/settings.json`, adjusted for this request's size/stakes.
- The final pre-playback round MUST iterate non-functional dimensions explicitly (tolerances + units, performance/memory envelopes, data scale, determinism) — never rely on NFRs surfacing on their own.
- Anything still open is written into the spec as `[NEEDS CLARIFICATION: …]` (cap 3) or `TBC:` markers — never left in chat.
- For interviews beyond a couple of rounds, keep coverage state in `docs/superpowers/elicitation/<SLUG>-state.md`.

**Brainstorming-gate mapping:** the user approval `superpowers:brainstorming` requires before implementation is delivered by THIS pipeline at Phase 3.5 — one consolidated stop. Creating the spec file is NOT approval; brainstorming's per-section approvals are also consolidated into Phase 3.5.

The output is a spec. Save it to:
```
docs/superpowers/specs/<SLUG>.md
```

**Mandatory spec shape — `docs-meta/SPEC_FORMAT.md` is the schema** (add any part the brainstorm output lacks): `weight:` frontmatter; `## User decisions (verbatim)`; `## Assumptions (machine, unconfirmed)`; `## Out of scope (confirmed)`; `## Functional requirements` (FR-NN, each with an EARS acceptance criterion — mandatory at standard/deep); `## Non-functional requirements` (NFR table: threshold WITH units, proving command, counter-metric); `## Analogs considered`; `## Success criteria` (observable, measurable, check-by — /validate will ask reality about exactly these); `## Test plan / seams`; `## URLs to verify` (frontend only). Prose in the conversation's language; IDs/statuses/markers always English.

**Frontend hint (NEW):** If the project has a frontend (`package.json` deps include `react|vue|svelte|next|nuxt|@angular/core|solid-js|preact|@builder.io/qwik|astro`, OR a root `index.html` exists alongside `package.json`), the spec MUST include a section:

```markdown
## URLs to verify
- /
- /<other-path-touched-by-this-feature>
```

If the brainstorm output omits this section for a frontend project, add it with at least `- /`. The visual sub-step in Phase 9 will navigate to each path.

---

## Phase 3: Critic gate-1

Invoke the `senior-critic` subagent (ships with this plugin — invoke it by name via the Task tool; it is NOT a file in the user's project):

```
Use the senior-critic subagent to review this spec at gate 1.
Inputs:
  - Spec: docs/superpowers/specs/<SLUG>.md  (schema: docs-meta/SPEC_FORMAT.md)
  - docs/architecture.md, docs/features.md, docs/roadmap.md, docs/risks.md
  - docs/glossary.md, docs/analysis/analogs.md
  - docs/model.md (when it exists) and the project class: jq -r '.pipeline.project_class' .claude/settings.json
  - All files under .claude/lessons/
  - Original user request: "<$ARGUMENTS>"
Slug: <SLUG>
Gate: 1
```

The critic saves a report and returns a one-line summary like:
`critic gate 1: 0 Critical / 2 Important / 1 Nice-to-have. Report: docs/superpowers/critic-reports/<SLUG>-gate1.md`

**Decision** — branch on the report's final fenced json verdict (`{"gate", "critical", "important", "nice", "status"}`; the LAST fenced json block in the report is the contract). Synchronous — wait for the user's answer; there are no timeouts:
- `status: fail` (Critical > 0): present the findings, ask `continue / address / override`.
  - `address` → re-run Phase 2 with critic findings as additional input. Max 2 retries; if still Critical, put the decision to the user again.
  - `override` → user must provide a written reason; append `**Gate decision:** override — <reason> (user, YYYY-MM-DD)` to the report file AND append a `docs/risks.md` row (Open table: `R-NNN` next unused, date, Source = which gate, finding, reason verbatim, review-by condition — ask for it with one ❓, link to the report).
  - `continue` → append `**Gate decision:** continue (user, YYYY-MM-DD)` to the report file (the pre-merge hook requires a recorded decision for any report with Critical findings), then proceed.
- `status: concerns` (Important-only): do NOT stop here — carry the Important findings, in full, into the Phase 3.5 playback digest (one consolidated stop).
- `status: pass` (Nice-to-have only): proceed; mention the one-line summary.

---

## Phase 3.5: Playback gate (the single blocking stop)

Present the decision digest and WAIT for explicit approval. This gate runs at every weight — only the digest size changes.

**standard / deep — full digest:**
- (a) your request, verbatim;
- (b) decisions made (from confirmed interview answers — the spec's "User decisions");
- (c) assumptions I made that you never stated (the spec's "Assumptions" + every critic gate-1 finding that names an unstated assumption, any severity, + all Important findings carried from Phase 3);
- (d) out of scope;
- (e) seams — the invariants, tolerances, and tests that will prove the work;
- (f) open markers: N × `[NEEDS CLARIFICATION]`, M × `TBC`.

**light — 3-line digest:** what I'll build / assumptions / what will prove it. Explicit approval still required.

**Rules:**
- The original request **authorizes planning only** — it is NOT approval to build, even if it says "just do it". Approval happens here, after the user sees the digest.
- On approval, append to the spec file: `**Approved by user:** YYYY-MM-DD (weight: <weight>)`.
- On approval, mint the feature's ID and requirements file:
  - `F_ID` = next unused `F-NNN` across `docs/features.md`, `docs/requirements/` filenames, and `docs/TRACEABILITY.md` (all three — an abandoned or parallel run must never double-mint).
  - Create `docs/requirements/<F_ID>-<slug>.md` per `docs-meta/REQUIREMENTS_FORMAT.md` from the approved spec: copy FR/NFR blocks AND the Success criteria table (all `unchecked`), give every requirement a `mid:` (`uuidgen | tr A-F a-f`), `status: in_progress` in the frontmatter, source lines pointing at the spec's User decisions.
  - Out-of-scope KB: any "Out of scope (confirmed)" item that is a CONCEPT beyond this one feature → append a row to `docs/analysis/out-of-scope.md` (concept, durable reason, date, this slug); feature-local exclusions stay in the spec.
  - Commit the approval durably (also makes both files visible inside a later worktree):
    ```bash
    git add "docs/superpowers/specs/<SLUG>.md" "docs/requirements/<F_ID>-<slug>.md"
    git commit -m "docs(spec): approved — <slug> (<F_ID>)"
    ```
- If the user amends anything: fold the amendment into the spec (updating "User decisions" verbatim), re-run critic gate-1 only if the change is material, and play back again.
- Open `TBC` markers > 0: say so explicitly. The user may answer them now, or approve anyway — approved-with-TBC markers stay in the spec as tracked debt and open the next interview.
- `deep` weight only: before presenting the digest, run one extra edge-case round (failure modes, boundary conditions) and fold the answers in.

---

## Phase 4: Plan

**Pre-condition:** the spec file must contain an `**Approved by user:**` line (written by Phase 3.5). If absent → STOP: the playback gate was skipped; return to Phase 3.5.

Invoke `superpowers:writing-plans` on the spec at `docs/superpowers/specs/<SLUG>.md`. **For any task implementing numeric computation, the plan MUST name the oracle type (taxonomy: `docs-meta/NUMERICS_TESTING.md`) and the tolerance with its one-line justification** — a numerical task without a named oracle is an incomplete plan. Save the plan to:
```
docs/superpowers/plans/<SLUG>.md
```

---

## Phase 5: Beads tasks

For each task in the plan:
```bash
bd create -t task "<task title from plan>" --description "<task description>"
```

Capture the IDs. For sequential tasks (Task N depends on Task N-1):
```bash
bd dep add <task-N-id> <task-N-1-id> --type blocks
```

Create a parent epic for the feature and add `parent-child` deps from each task to the epic:
```bash
# --silent prints only the issue ID; beads ID prefixes are project-derived, never assume "bd-"
EPIC_ID=$(bd create -t epic "<feature description>" --silent)
bd dep add <task-id> $EPIC_ID --type parent-child
```

Update `docs/features.md`: move/add the feature to "In progress" as `- [ ] [<F_ID>] <slug> — <one-line> — in-progress` (F_ID minted at Phase 3.5) with the epic ID.

---

## Phase 6: Worktree (conditional)

If the plan has > 3 sub-tasks, invoke `superpowers:using-git-worktrees`. This creates a worktree on a branch named `feature/<slug>`.

If ≤ 3 sub-tasks, work directly on a feature branch:
```bash
git checkout -b feature/<slug>
```

---

## Phase 7: TDD loop

Loop until `bd ready` returns no tasks blocked-by this epic:

```
For each ready task:
  - bd update <id> --claim
  - Invoke superpowers:test-driven-development for this task
    (RED → verify-fail → GREEN → verify-pass → REFACTOR)
  - After GREEN: git add -A && git commit -m "feat(<slug>): <task title>"
  - bd close <id> --reason "Done — see commit <sha>"
```

**Stop conditions:**
- 3 failed RED→GREEN attempts on a single task → stop, surface to user
- Test that should fail doesn't fail → stop (test is broken; for numeric changes use the feature-flag honest-RED protocol from `docs-meta/NUMERICS_TESTING.md`)
- Tolerance chosen or loosened to make a test pass → stop (derive why the bound is correct, or treat it as a real bug — `docs-meta/NUMERICS_TESTING.md`)
- Verification command fails → stop

**After sign-off, open decisions do not stop the build:** a decision that surfaces mid-TDD is recorded in the spec as an Assumption plus a `TBC:` marker, the conservative option is taken, and gate-2 surfaces it (see `docs-meta/ELICITATION.md`, "Post-approval"). Exception: if it invalidates the approved digest (scope, interface, stated tolerance) → STOP and re-play Phase 3.5.

---

## Phase 8: Critic gate-2

Invoke the `senior-critic` subagent at gate 2:

```
Use the senior-critic subagent to review at gate 2.
Inputs:
  - Diff: git diff main..HEAD (or git diff main..feature/<slug> if in worktree)
  - Spec: docs/superpowers/specs/<SLUG>.md
  - Requirements file: docs/requirements/<F_ID>-<slug>.md
  - docs/architecture.md, docs/features.md, docs/risks.md
  - docs/superpowers/runs/tool-ledger.jsonl — harness-recorded ground truth: a command the diff or spec claims was run that never appears here did not run
  - The layer-status line (re-run scripts/pipeline/layer-status.sh)
  - All files under .claude/lessons/
Slug: <SLUG>
Gate: 2
```

Critic saves report, returns one-line summary.

**Fresh-context verification (before findings reach the user):** if the draft report has any Critical finding, or the run weight is `deep`, dispatch the senior-critic again in **verification mode** on the saved report (it re-reads only the cited evidence, drops what does not reproduce, rewrites the counts and the json verdict). The decision below branches on the VERIFIED report.

**Auto-write suggested memories (NEW):**

Read the critic's saved report file (path returned in the summary line). Parse the section beginning with `## Memories to capture (suggested)`. For each bullet entry of the form `` - `<slug>`: <summary> — <reason> `` or `` - [decision] `<slug>`: <summary> — <reason> `` (both shapes get a memory; the `[decision]` shape additionally gets an ADR — see below):

```bash
# For each suggested memory:
mcp__serena__write_memory({
  name: "<slug>",
  content: "<summary>\n\nCaptured by senior-critic at gate-2 of /feature \"$ARGUMENTS\" on YYYY-MM-DD.\n\n<reason>"
})
```

If a memory with that slug already exists (check via `mcp__serena__list_memories`), append `## Update YYYY-MM-DD` section to it instead of overwriting.

If `mcp__serena__write_memory` fails (Serena MCP not running), warn once with the slug and continue — do NOT block the pipeline.

**Decision-class suggestions → ADR:** any suggestion the critic prefixed with `[decision]` ALSO becomes a committed decision record: create `docs/decisions/NNNN-<slug>.md` per `docs-meta/ADR_FORMAT.md` (NNNN = next free number), filling Context/Decision/Consequences from the suggestion and Binds from the F/FR/NFR ids in scope. Include it in the Phase 11 docs commit. The Serena memory is still written — it is the agent-facing mirror.

Print a one-line summary: `Memories captured: <N> new, <M> updated, <P> skipped. ADRs written: <K>`.

**Decision** — branch on the report's final fenced json verdict (same contract as gate-1). Synchronous — wait; no timeouts:
- `status: fail` (Critical > 0): present the findings, ask `continue / address / override`.
  - `address` → for each Critical/Important finding, run `bd create` to add a new task, then loop back to Phase 7 for those tasks. Max 2 cycles.
  - `override` → append `**Gate decision:** override — <reason> (user, YYYY-MM-DD)` to the report AND append a `docs/risks.md` row (same protocol as gate-1).
  - `continue` → append `**Gate decision:** continue (user, YYYY-MM-DD)` to the report, then proceed.
- `status: concerns` (Important-only): present the Important findings (content, not just the count) and ask `continue / address`.
- `status: pass`: proceed.

---

## Phase 9: Verify

Invoke `superpowers:verification-before-completion`. Identify and run the proving command(s) for this feature:
- Test suite: `<project's test command>`
- Lint: `<lint command if configured>`
- Type check: `<typecheck command if configured>`
- Build: `<build command if configured>`

For each: run fresh, read full output, capture exit code. If any fail → STOP, surface output, do not proceed.

### Phase 9b: Visual verification (frontend only)

After the proving commands above pass, run the visual gate. All bash for this phase lives in the plugin's `scripts/pipeline/` — testable files, not markdown. Blocks are separate shells: resolve the script dir in EVERY block that calls one:

```bash
PIPE="$(ls -d "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline"/*/ 2>/dev/null | sort -V | tail -1)scripts/pipeline"
```

**Detect frontend:**

```bash
bash "$PIPE/detect-frontend.sh"    # prints HAS_FRONTEND=yes|no plus the rule that fired
```

**Skip rule (applies to EVERY visual skip below):** a skipped gate still writes its verdict — hooks branch on artifact existence, and "skipped honestly" must be distinguishable from "died mid-verify":

```bash
mkdir -p "docs/superpowers/visual-evidence/<SLUG>"
printf '{"gate":"visual","slug":"<SLUG>","status":"skipped","blocking":false}\n' > "docs/superpowers/visual-evidence/<SLUG>/verdict.json"
```

If `HAS_FRONTEND=no` → write the skip verdict (above) and go directly to Phase 9c.

**Preflight** (settings, Playwright MCP check, dev server, URL extraction). The spec file is resolved statelessly — prefer the /fix diagnosis when it exists:

```bash
SPEC_FILE="docs/superpowers/specs/<SLUG>.md"
[ -f "docs/superpowers/specs/<SLUG>-diagnosis.md" ] && SPEC_FILE="docs/superpowers/specs/<SLUG>-diagnosis.md"
bash "$PIPE/visual-preflight.sh" "$SPEC_FILE"
```

Read its output: `MODE`, `BASE_URL`, optional `SKIP_VISUAL`, optional `DEV_PID`, and the `URLS<<EOF … EOF` block. Exit 1 with `SKIP_VISUAL=fail` means a `required`-mode preflight failure → STOP. `SKIP_VISUAL=yes` → write the skip verdict and go to Phase 9c.

**Prepare evidence dirs and record the URL list** (the verdict script reads `urls.txt`):

```bash
EVIDENCE_DIR="docs/superpowers/visual-evidence/<SLUG>"
mkdir -p "$EVIDENCE_DIR/screenshots" "$EVIDENCE_DIR/snapshots"
printf '%s\n' <each URL from URLS> > "$EVIDENCE_DIR/urls.txt"
> "$EVIDENCE_DIR/console.txt"
```

**For each URL, drive Playwright MCP** (MCP tool calls, not bash). Compute `<urlslug>` per the slugify rule in `visual-verdict.sh` (`/` → `_root`; otherwise lowercase, strip the query, non-alphanumerics → `_`):

1. `mcp__playwright__browser_navigate({ url: "<BASE_URL><path>" })`
2. `mcp__playwright__browser_snapshot({ filename: "<EVIDENCE_DIR>/snapshots/<urlslug>.md" })`
3. `mcp__playwright__browser_take_screenshot({ type: "png", fullPage: true, filename: "<EVIDENCE_DIR>/screenshots/<urlslug>.png" })`
4. `mcp__playwright__browser_console_messages({ level: "warning" })` — append to `<EVIDENCE_DIR>/console.txt` under a `=== <path> ===` header

**Verdict** (writes `summary.md` + machine-readable `verdict.json`):

```bash
PIPE="$(ls -d "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline"/*/ 2>/dev/null | sort -V | tail -1)scripts/pipeline"
# MODE re-resolved HERE — never carried across bash blocks (command-bash-block-state)
MODE=$(jq -r '.pipeline.visual_verify.mode // "required"' .claude/settings.json 2>/dev/null || echo required)
bash "$PIPE/visual-verdict.sh" "<SLUG>" "$MODE"
```

**Cleanup dev server:**

```bash
[ -f docs/superpowers/runs/dev-server.pid ] && kill "$(cat docs/superpowers/runs/dev-server.pid)" 2>/dev/null
rm -f docs/superpowers/runs/dev-server.pid
```

**Apply verdict** — read `$EVIDENCE_DIR/verdict.json` (never a shell variable from another block):

- `status: pass` (or `skipped`) → proceed to Phase 9c.
- `status: fail`, `blocking: true` → STOP. Print `summary.md`. Do NOT merge (the plugin's pre-merge hook also blocks on this verdict).
- `status: fail`, `blocking: false` → warn, print summary, proceed to Phase 9c.

### Phase 9c: Quantitative verification (compute classes / declared NFRs)

One stateless block — resolve mode, then run the gate script:

```bash
PIPE="$(ls -d "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline"/*/ 2>/dev/null | sort -V | tail -1)scripts/pipeline"
QMODE=$(jq -r '.pipeline.quant_verify.mode // "by_class"' .claude/settings.json 2>/dev/null || echo by_class)
PCLASS=$(jq -r '.pipeline.project_class // "unset"' .claude/settings.json 2>/dev/null || echo unset)
if [ "$QMODE" = "by_class" ]; then
  case "$PCLASS" in numerical-library|simulation|data-pipeline) QMODE=required ;; *) QMODE=skip ;; esac
fi
REQ="docs/requirements/<F_ID>-<slug>.md"; [ -f "$REQ" ] || REQ="-"
# skip only when NOTHING is declared anywhere: NFR commands, global commands, budgets
DECLARED=no
{ [ "$REQ" != "-" ] && grep -q 'Proving command:' "$REQ"; } && DECLARED=yes
[ "$(jq -r '(.pipeline.quant_verify.property_test_command // "") + (.pipeline.quant_verify.benchmark_command // "") + (.pipeline.quant_verify.tolerance_report_command // "")' .claude/settings.json 2>/dev/null)" != "" ] && DECLARED=yes
[ "$(jq -r '.pipeline.quant_verify.budgets // [] | length' .claude/settings.json 2>/dev/null)" != "0" ] && DECLARED=yes
[ "$QMODE" = "skip" ] && [ "$DECLARED" = "yes" ] && QMODE=best_effort
if [ "$QMODE" = "skip" ]; then
  mkdir -p "docs/superpowers/quant-evidence/<SLUG>"
  printf '{"gate":"quant","slug":"<SLUG>","status":"skipped","blocking":false}\n' > "docs/superpowers/quant-evidence/<SLUG>/verdict.json"
  echo "quant gate: skipped (no checks declared) — skip verdict written"
else
  bash "$PIPE/quant-verify.sh" "<SLUG>" "$REQ" "$QMODE"
fi
```

The script implements: NFR proving commands + `verify.method` declarations (Test evidence runs via `pipeline.quant_verify.test_runner`; Analysis/Inspection/Review evidence files must exist; declared-but-unrunnable or missing → `partial`) + global commands + budgets, one run per seed with `SEED` exported (**pass^k** — deterministic oracles pass only when ALL seeds pass; empty `seeds` = one run without `SEED`; **pass@k** is reserved for NFRs explicitly declared statistical), the mutation sub-step per `pipeline.quant_verify.mutation` (advisory survivors → Important findings; `required` with empty `mutation_command` → `partial`; the command receives `MUTATION_THRESHOLD` from `pipeline.quant_verify.mutation_threshold` and must exit nonzero when the score falls below it), and the **anti-overclaim verdict**: `verified` only when every declared check executed and passed; declared-but-unexecuted → `partial` (**zero collected checks → `partial` in `required` mode, `skipped` in `best_effort` — never `verified`**: an empty run-manifest proves nothing); any failure → `failed`. Evidence: `summary.md`, `run-manifest.md`, `verdict.json` under `docs/superpowers/quant-evidence/<SLUG>/`.

**Code-link audit (advisory, prose step):** scan the diff's source files for `@relation(F-*/FR-*)` markers; for every requirement `code:` entry recompute the symbol-body sha256 — a mismatch is recorded as a **suspect** link in summary.md (re-verify, not a block); public numerical functions in the diff without markers, and requirements with no linked code/test, become coverage notes. Cross-check claimed commands against the hook ledger `docs/superpowers/runs/tool-ledger.jsonl` — a check "run" that never appears in the harness ledger did not run.

**Apply** (from `verdict.json`):

- `verified` → Phase 10.
- `partial`/`failed` + `QMODE=required` → STOP, print `summary.md`, ask `address / override`: `address` → `bd create` a task per failed/unexecuted check, loop back to Phase 7, then re-run Phase 8 (the critic reads the fresh quant evidence) and Phase 9. `override` → written reason + `docs/risks.md` row, same protocol as the critic gates.
- `partial`/`failed` + `best_effort` → warn, proceed. A verdict without a run-manifest does not count as `verified`.

---

## Phase 10: Finish

Read `.claude/settings.json`'s `pipeline.finish_mode`. Default `merge`.

**If `merge`:**
```bash
git checkout main
git merge --no-ff feature/<slug> -m "feat: <feature description> (merged from feature/<slug>)"
git branch -d feature/<slug>
# If worktree was used:
git worktree remove ../<worktree-dir>
```

**If `pr`:**
```bash
gh pr create \
  --title "feat: <feature description>" \
  --body "$(cat <<EOF
## Summary
<one paragraph from spec>

## Critic review
Gate 1: <summary>
Gate 2: <summary>
Reports: docs/superpowers/critic-reports/<SLUG>-gate{1,2}.md

## Tasks
$(bd list --epic $EPIC_ID --status closed | head -20)

🤖 Generated by /feature pipeline
EOF
)"
```

Do NOT push to remote. Print the merge SHA or PR URL and tell the user to push manually if desired.

---

## Phase 11: Master Plan update

1. `docs/features.md`: move the feature from "In progress" to "Shipped" (the version stamp is added later by `/release`):
   ```
   - [x] [<F_ID>] <slug> — <description> — shipped YYYY-MM-DD
   ```
   Append a Change-history row and bump `doc_version`.

2. `docs/requirements/<F_ID>-<slug>.md`: set frontmatter `status: shipped`; append a Change-history row.

3. `docs/TRACEABILITY.md`: append one row (create the file with a header table if missing):
   ```
   | <F_ID> | <slug> | specs/<SLUG>.md | plans/<SLUG>.md | <gate-1 report> | <gate-2 report> | <evidence dir or —> | <merge SHA> | YYYY-MM-DD |
   ```

```bash
git add docs/features.md docs/requirements/ docs/TRACEABILITY.md docs/decisions/ docs/risks.md 2>/dev/null
git commit -m "docs: feature shipped — <slug> (<F_ID>)"
```

Close the beads epic and the run:
```bash
bd close $EPIC_ID --reason "Shipped — merge SHA <sha>"
rm -f docs/superpowers/runs/current.json   # run complete — hooks stand down
```

---

## Phase 12: Final report (not numbered as a pipeline phase — just output)

```
✓ Feature shipped: <description>

Spec:    docs/superpowers/specs/<SLUG>.md
Plan:    docs/superpowers/plans/<SLUG>.md
Critic:  gate-1 (<summary>), gate-2 (<summary>)
Tasks:   <N> beads tasks closed
Diff:    <merge-sha or PR URL>
Tests:   <pass/fail summary>
Layers:  <the layer-status.sh line from ground — re-run it here if any layer changed>

Next: /feature "<next thing>" or git push (manual).
```

---

## Error handling summary

| Failure | Action |
|---|---|
| Master Plan unfilled | Stop, suggest `/init` |
| Interview decision open | Put it to the user as a frontier round, wait (no timeouts) |
| Playback gate not approved | Fold amendments into the spec, play back again; nothing is built without approval |
| Critic gate-1 Critical, user `address` | Re-run brainstorm with findings; max 2 retries |
| Critic gate-2 Critical, user `address` | Add tasks, re-loop TDD; max 2 cycles |
| TDD attempt loop > 3 | Stop, surface |
| Verify command non-zero | Stop, surface |
| Visual gate (9b) FAIL, mode=required | Stop, print summary.md, do NOT merge |
| Quant gate (9c) partial/failed, mode=required | Stop, ask address/override; address → bd tasks per failed check → Phase 7 → re-run Phase 8 with fresh quant evidence |
| Merge conflict | Stop, surface, do NOT auto-resolve |
| `gh` not installed when `pr` mode | Fall back to `merge` mode, warn user |

## Constraints

- This command should NEVER push to a remote.
- This command should NEVER skip critic gates silently.
- This command should NEVER claim done without Phase 9 verification passing.
- This command should NEVER update `docs/architecture.md` (only `/plan-improve` does that).
