# Pipeline reference

This document describes the 6-command AI development pipeline that ships with this project template. It is the **source of truth** referenced from `CLAUDE.md`.

## The 6 user-facing commands

### `/init "<app description>"`
Bootstrap a new project. Asks ~3 clarifying questions, fills in `docs/architecture.md`, `docs/features.md`, `docs/roadmap.md`, scaffolds the project skeleton, runs `git init`, runs `bd init`, makes the first commit. Refuses to run if the current folder already contains feature code.

### `/plan-improve "<change to master plan>"`
Refine the Master Plan without writing any feature code. Loads the three plan files, may ask clarifying questions, runs the critic, writes updated plan files, commits. Use this when you realize the plan is missing something or has the wrong shape.

### `/feature "<description>"`
Build new functionality end-to-end. Runs the full automatic pipeline (see "Internal phases" below). The user fires this and walks away — only intervenes when the brainstorm has a real clarifying question or the critic surfaces a Critical finding.

### `/improve "<change to existing X>"`
Same pipeline as `/feature`, but the ground phase emphasizes finding the existing code paths to change. Use when modifying behavior of something already shipped. **Does not** add new features (those go through `/feature`).

### `/fix "<bug description>"`
Same pipeline shape, but uses systematic-debugging instead of brainstorming, and ends by writing a lesson file to `.claude/lessons/` so the same bug never costs twice.

### `/lesson`
Manually record a lesson learned. Prompts for trigger / symptom / root_cause / prevention. Rarely needed — `/fix` writes lessons automatically.

---

## Internal phases (run automatically inside `/feature`, `/improve`, `/fix`)

| # | Phase | What it does | Implemented by |
|---|---|---|---|
| 1 | ground | Reads `docs/architecture.md`, `docs/features.md`, `docs/roadmap.md`, all `.claude/lessons/*.md`. Detects libraries from package manifests, queries Context7. | inline in command file |
| 2 | brainstorm | Generates spec → saves to `docs/superpowers/specs/YYYY-MM-DD-<slug>.md` | `superpowers:brainstorming` |
| 3 | critic-1 | Senior-critic reviews the spec | `.claude/agents/senior-critic.md` |
| 4 | plan | Decomposes into 2-5 min tasks | `superpowers:writing-plans` |
| 5 | bd-tasks | Creates beads tasks + dependencies | `bd create`, `bd dep add` |
| 6 | worktree (conditional) | Isolates work in a worktree if >3 sub-tasks | `superpowers:using-git-worktrees` |
| 7 | TDD loop | RED → verify-fail → GREEN → verify-pass → REFACTOR → `git commit` per task | `superpowers:test-driven-development` |
| 8 | critic-2 | Senior-critic reviews the cumulative diff | `.claude/agents/senior-critic.md` |
| 9 | verify | Runs proving commands, reads exit codes | `superpowers:verification-before-completion` |
| 10 | finish | Merges to main OR opens PR (per `pipeline.finish_mode` in settings.json) | `superpowers:finishing-a-development-branch` |
| 11 | master-plan-update | Moves feature in `docs/features.md` to "Shipped" | inline in command file |

`/fix` replaces phase 2 with `superpowers:systematic-debugging`, replaces phase 11 with lesson-write.

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

**Default if user doesn't respond:** `address` if any Critical findings, `continue` if only Nice-to-have.

---

## Git policy

- **Automated by pipeline:** `git init`, `git add`, `git commit`, branch creation, `git worktree add`, local merge of feature branch
- **Manual (user only):** `git push` to any remote

---

## Lessons system

- Storage: `.claude/lessons/YYYY-MM-DD-<slug>.md`
- Schema: `docs-meta/LESSON_FORMAT.md`
- Loading: every internal phase reads them; critic cites them
- Creation: `/fix` writes one automatically; `/lesson` writes one manually
- Pruning: manual only; never auto-delete

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
