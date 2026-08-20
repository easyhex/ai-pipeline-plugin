# Pipeline reference

This document describes the 12-command AI development pipeline that ships with this project template. It is the **source of truth** referenced from `CLAUDE.md`.

## The 12 user-facing commands

### `/init "<app description>"`
Bootstrap a new project. Runs a frontier-round interview (stakes / user / stack / scenarios / quality ranking / forced NFR round per `docs-meta/ELICITATION.md`), fills in `docs/architecture.md`, `docs/features.md`, `docs/roadmap.md`, seeds `docs/glossary.md` and installs `docs/risks.md` + `docs/analysis/analogs.md` (optional web-search fill), confirms every drafted line with the user BEFORE the first commit, scaffolds the project skeleton, runs `git init`, runs `bd init`. An existing codebase is not refused: adopt mode reverse-engineers the Master Plan from the real code and git history (everything derived is `(proposed — unconfirmed)` until line-by-line confirmation), never overwrites existing files, and commits only the pipeline files.

### `/plan-improve "<change to master plan>"`
Refine the Master Plan without writing any feature code. Loads the four Master Plan files (plus glossary/analogs when relevant), asks open decisions as frontier rounds, runs the critic, writes updated files with `doc_version` bumps + change-history rows, commits. Also the command that retires `docs/risks.md` rows and clears `(proposed — unconfirmed)` tags.

### `/feature "<description>"`
Build new functionality end-to-end. Interviews the user to shared understanding (frontier rounds), runs the critic on the spec, plays the spec back for explicit sign-off at Phase 3.5 — and only then runs autonomously through plan → TDD → critic → verify → finish, stopping post-sign-off only for critic findings that need the user's decision or for failures. See "Internal phases" below.

### `/improve "<change to existing X>"`
Same pipeline as `/feature`, but the ground phase emphasizes finding the existing code paths to change. Use when modifying behavior of something already shipped. **Does not** add new features (those go through `/feature`).

### `/fix "<bug description>"`
Same pipeline shape, but uses systematic-debugging instead of brainstorming, and ends by writing a lesson file to `.claude/lessons/` so the same bug never costs twice.

### `/lesson`
Manually record a lesson learned (trigger / symptom / root_cause / prevention). Rarely needed — `/fix` writes lessons automatically. **`/lesson distill`** compiles the lesson pile: clusters recurring patterns into `docs-meta/DISTILLED.md` rules (every processed lesson lands in a rule or the un-clustered list), advances `docs-meta/.lesson-cursor`; ground phases then read the compiled rules first and only the undistilled tail raw.

### `/remember "<fact>"`
Capture a project-specific fact to Serena memory. Plain wrapper around `mcp__serena__write_memory`. Used rarely — most memories come automatically from senior-critic at gate-2.

### `/questionnaire "<topic>"`
Generate a requirements questionnaire for someone else's head (client, domain expert, stakeholder). Interviews you only about the send — who it goes to and what must come back — then writes a fill-in Markdown document to `docs/requirements/`. Answered questionnaires are read by the next `/feature`/`/improve` ground phase; answers become "User decisions" with provenance.

### `/resume [slug]`
Continue an interrupted pipeline run. Derives the true position from artifact existence (spec → approval line → plan → beads tasks → gate reports → evidence → merge) and reconciles it with the `docs/superpowers/runs/current.json` cache — files win over the cache. Never re-mints an F-ID; never re-runs an approved playback.

### `/validate [feature]`
Falsify shipped guesses against reality: re-runs machine-checkable success criteria itself, asks for outcome evidence per criterion (frontier format, "I don't know" keeps it unchecked), records met/missed with evidence into the requirements files, and routes missed criteria as a reprioritization proposal to `/plan-improve`. Features shipped without criteria are listed as "unfalsifiable".

### `/deprecate "<feature>"`
The non-additive path: impact scan (traceability + supersedes chains + @relation call sites), deep-weight playback over the impact list, a committed migration plan, code removal via the standard TDD loop with the gate-2 critic told the break is INTENDED (it reviews the migration, not the regression), `BREAKING` change-history rows that make the next `/release` a major bump.

### `/release`
Cut a product release: proposes the next semver from shipped-since-last-tag features (confirmed by one ❓), writes a human-register `CHANGELOG.md` from spec Goals (never from commit messages) including a mid-based "requirements changed since last release" section, stamps `in vX.Y.Z` into `docs/features.md`, commits and tags locally. Never pushes.

---

## Internal phases (run automatically inside `/feature`, `/improve`, `/fix`)

| # | Phase | What it does | Implemented by |
|---|---|---|---|
| 1 | ground | Reads the four Master Plan files + `docs/glossary.md`, `docs/analysis/analogs.md`, `docs/analysis/out-of-scope.md`, relevant `docs/requirements/F-*.md`, answered questionnaires, `docs-meta/DISTILLED.md` first + the undistilled lesson tail. Detects libraries from package manifests, queries Context7. + load matching memories (Serena). | inline in command file |
| 2 | brainstorm | Generates spec → saves to `docs/superpowers/specs/YYYY-MM-DD-<slug>.md` | `superpowers:brainstorming` |
| 3 | critic-1 | Senior-critic reviews the spec | `senior-critic` subagent (ships with the ai-pipeline plugin) |
| 3.5 | playback gate | The single blocking stop: decision digest (request verbatim / decisions / assumptions / out of scope / seams / open markers) → explicit user approval, recorded in the spec. On approval: F-ID minted + living requirements file created (`docs/requirements/`, per REQUIREMENTS_FORMAT.md, mid uuids). The original request authorizes planning only. | inline in command file |
| 4 | plan | Decomposes into 2-5 min tasks (pre-condition: spec carries `**Approved by user:**`) | `superpowers:writing-plans` |
| 5 | bd-tasks | Creates beads tasks + dependencies | `bd create`, `bd dep add` |
| 6 | worktree (conditional) | Isolates work in a worktree if >3 sub-tasks | `superpowers:using-git-worktrees` |
| 7 | TDD loop | RED → verify-fail → GREEN → verify-pass → REFACTOR → `git commit` per task | `superpowers:test-driven-development` |
| 8 | critic-2 | Senior-critic reviews the cumulative diff. + auto-write suggested memories. | `senior-critic` subagent (ships with the ai-pipeline plugin) |
| 9 | verify | Runs proving commands, reads exit codes | `superpowers:verification-before-completion` |
| 9b | visual-verify (frontend only) | Drives Playwright MCP across spec's `## URLs to verify`, captures screenshot + a11y snapshot + console; verdict in `docs/superpowers/visual-evidence/<slug>/summary.md` | inline in command file |
| 9c | quant-verify (compute classes / declared NFRs) | Runs every NFR proving command per seed (`pipeline.quant_verify`, pass^k for deterministic oracles), mutation sub-step, @relation/hash link audit; verdict `verified`/`partial`/`failed` (anti-overclaim: unexecuted oracle → `partial`) + `run-manifest.md` in `docs/superpowers/quant-evidence/<slug>/` | inline in command file (canonical; `/improve`/`/fix` carry deltas) |
| 10 | finish | Merges to main OR opens PR (per `pipeline.finish_mode` in settings.json) | `superpowers:finishing-a-development-branch` |
| 11 | master-plan-update | Moves feature in `docs/features.md` to "Shipped"; flips the requirements file to `shipped`; appends the `docs/TRACEABILITY.md` row (F-ID → spec → plan → gates → evidence → merge SHA) | inline in command file |

`/fix` replaces phase 2 with `superpowers:systematic-debugging`, runs Phase 3.5 as a light digest over its diagnosis, and replaces phase 11 with lesson-write.

**Ceremony weight:** `.claude/settings.json` → `pipeline.default_weight` (`light` / `standard` / `deep`, written by `/init`'s stakes answer) seeds the ➡️ recommendation of `/feature`'s weight question; the confirmed weight is recorded in the spec frontmatter and scales the playback digest (see `docs-meta/ELICITATION.md`).

---

## Critic protocol

The senior-critic runs at two gates and produces a markdown report:

```
docs/superpowers/critic-reports/YYYY-MM-DD-<slug>-gate{1,2}.md
```

**Output sections:** Critical / Important / Nice to have / Lessons applied / Lessons NOT applied (with reason)

**User options when critic returns:**

| User says | Behavior |
|---|---|
| `continue` | Accept findings, proceed to next phase |
| `address` | Re-run prior phase with critic findings as additional input. **Gate 1 → re-runs brainstorm. Gate 2 → re-runs plan to create new tasks for each Critical/Important, then loops back to TDD for those tasks.** |
| `override` | User accepts the risk; must leave a written reason that gets appended to the report file |

**Gate decisions are synchronous** — the pipeline waits for an answer; there are no timeouts and no self-decided defaults. Outcome mapping: Critical → stop and ask; **Important-only** at gate-1 → findings are carried, in full, into the Phase 3.5 playback digest (one consolidated stop); **Important-only** at gate-2 → present the findings and ask `continue / address`; Nice-to-have only → proceed.

---

## Enforcement hooks (v0.7 — ship with the plugin, not this project)

The plugin registers harness hooks that no-op outside an active pipeline run (`docs/superpowers/runs/current.json`):

| Hook | What it enforces |
|---|---|
| PostToolUse (Bash) | appends every Bash call to `docs/superpowers/runs/tool-ledger.jsonl` — ground truth the verify phase and critic check claimed commands against |
| PreToolUse (Bash) | blocks `git merge` / `git push` / `gh pr create` while a blocking `verdict.json` (visual/quant) stands or the newest critic report has unresolved Critical findings without an override |
| Stop | blocks session end ONCE while the run sits in phases 9–10 with no gate verdict written (`stop_hook_active` loop safety) |
| PreCompact | snapshots run position + ledger tail before context destruction |
| UserPromptSubmit | injects a compact digest (lessons index, memory names, active-run line) into every prompt of every pipeline PROJECT (run or not — the only hook active outside runs) |

Abandoning a run: delete `docs/superpowers/runs/current.json` — all hooks stand down.

## Git policy

- **Automated by pipeline:** `git init`, `git add`, `git commit`, branch creation, `git worktree add`, local merge of feature branch
- **Manual (user only):** `git push` to any remote

---

## Lessons system

- Storage: `.claude/lessons/YYYY-MM-DD-<slug>.md`
- Schema: `docs-meta/LESSON_FORMAT.md`
- Loading: ground reads `docs-meta/DISTILLED.md` (compiled rules) first, then the undistilled tail past `docs-meta/.lesson-cursor`; both critic gates and `/fix` still read every lesson; critic cites them
- Creation: `/fix` writes one automatically; `/lesson` writes one manually
- Pruning: manual only; never auto-delete

---

## Context layers

The pipeline reads from 6 context layers:

| Layer | Storage | Stores | Read in | Written in |
|---|---|---|---|---|
| **Beads** | `.beads/` | tasks + dependencies | every `bd ready` | every command |
| **Lessons** | `.claude/lessons/*.md` | bug prevention rules | every phase (lesson trigger match) | `/fix`, `/lesson` |
| **Master Plan** | `docs/{architecture,features,roadmap,risks}.md` + `docs/glossary.md`, `docs/analysis/analogs.md`, `docs/requirements/` | what+how+priorities+accepted risk+language+requirements | ground phase | `/init`, `/plan-improve`, `/feature`+`/improve` (features.md, requirements, traceability), gate overrides (risks.md) |
| **Context7** | live MCP query | external library docs | ground phase | n/a (read-only) |
| **Serena memory** | `.serena/memories/*.md` | project conventions + design decisions | `/feature`/`/improve` ground | senior-critic at gate-2 (gate-1 for `/plan-improve`), `/remember` |
| **Playwright MCP** | live browser session | live UI state (screenshots, a11y, console) | Phase 9b of `/feature`, `/improve`, `/fix` | n/a (read-only — evidence lands in `docs/superpowers/visual-evidence/<slug>/`) |

The layers do NOT overlap by design:
- Bug? → lesson
- Task? → bead
- Architectural decision? → master plan (`architecture.md`)
- External library quirk? → Context7 (or Serena memory if it's PROJECT-specific use of that library)
- Project convention or ambient knowledge? → Serena memory

---

## Edge cases (orchestrator must handle)

| Situation | Behavior |
|---|---|
| `/init` in non-empty folder | Refuse with explanation; suggest using an empty folder |
| `/feature` before `/init` (no Master Plan) | Refuse; tell user to run `/init` first |
| Context7 lookup fails | Log warning, continue, note in spec "library docs unavailable, proceed with caution" |
| Critic gate-1 Critical + user picks `address` | Re-run brainstorm with critic findings injected |
| Critic gate-2 Critical + user picks `address` | Re-run plan with critic findings → new tasks → TDD loop on new tasks |
| TDD test never reaches GREEN after 3 attempts | Stop loop, surface to user, do NOT silently continue |
| Verify command exits non-zero | Stop pipeline, surface output, do NOT claim done |
| `bd init` already done | Skip; continue with rest of bootstrap |
| Lesson file has malformed YAML | Log warning, continue (lessons are advisory) |
