# AI Development Pipeline — Design Spec

**Date:** 2026-04-25
**Owner:** vladislav (nemtsovkz@gmail.com)
**Status:** Draft for review

---

## 1. Goal

Replace the current ad-hoc, ceremony-heavy workflow with a small, opinionated pipeline that:

1. Can be **dropped into any new project** by copying one folder.
2. Drives the entire feature lifecycle (design → implement → review → ship) with **6 user-facing commands**.
3. Runs every internal phase (brainstorm, plan, TDD, critic, git, verify, finish) **automatically** without per-step user input.
4. Includes a **B-style senior-engineer critic** that runs at two gates (post-design, post-implementation).
5. Builds up a **lessons-learned flywheel** so the same bug never costs twice.
6. Steals the best parts of AI Factory (codebase grounding, MCP/lib check, learning loop, step-by-step explicit phases) without losing what already works (Superpowers TDD discipline, Beads persistence, Template Bridge specialists, Context7 live docs).

## 2. Non-goals

- **Not** a replacement for Superpowers, Beads, Template Bridge, or Context7. They remain installed; this design *orchestrates* them.
- **Not** cross-agent (Cursor/Copilot/etc.). Claude Code only.
- **Not** a public skills marketplace.
- **No** rewriting Superpowers internals.

## 3. The two modes

### Mode 1 — Project bootstrap (one time)

```
/init "<one-line app description>"
   → reads description
   → asks ~3 clarifying questions
   → writes Master Plan (split into 3 files, see §5)
   → scaffolds project skeleton (folders, package.json/pyproject/etc.,
     .gitignore, README, first commit)
   → bd init
   → reports: "Bootstrap done. Next: /feature \"first thing to build\""

/plan-improve "<change to master plan>"
   → loads Master Plan files
   → asks clarifying questions if needed
   → critic reviews proposed change
   → writes updated plan files
   → commits change
```

Bootstrap is finished when the Master Plan reflects the app you want to build. **Zero feature code is written during bootstrap.**

### Mode 2 — Per-feature work (recurring)

```
/feature "<new functionality>"          # for new behavior
/improve "<change to existing X>"       # for modifying existing behavior
/fix    "<bug description>"             # for bugs (auto-records lesson)
```

Each of these is a **single user command** that internally runs the full pipeline:

```
ground   → brainstorm → critic-1 → plan → bd-tasks
       → worktree → for each task: TDD (red/green/refactor → auto-commit)
       → critic-2 → verify → finish (merge or PR) → master-plan-update
```

The user types one command and walks away. Every phase below is internal:

| Phase | Implementation |
|---|---|
| ground | Read `docs/architecture.md`, `docs/features.md`, `.claude/lessons/`, run Context7 `resolve-library-id` + `query-docs` for libraries detected in package manifests |
| brainstorm | `superpowers:brainstorming` — questions + 2-3 approaches + spec → `docs/superpowers/specs/YYYY-MM-DD-<slug>.md` |
| critic-1 | Senior-critic agent reviews the spec against Master Plan + lessons; emits findings; user gets one consolidated message + can intervene or pass |
| plan | `superpowers:writing-plans` → 2-5 min sub-tasks |
| bd-tasks | `bd create` for each sub-task + `bd dep add` for ordering, all under one parent epic |
| worktree | `superpowers:using-git-worktrees` if work is non-trivial (>3 sub-tasks) |
| TDD | `superpowers:test-driven-development` — RED → verify-fail → GREEN → verify-pass → REFACTOR → `git commit` |
| critic-2 | Senior-critic agent reviews the diff against the spec + lessons + Master Plan |
| verify | `superpowers:verification-before-completion` — runs proving commands, reads exit code |
| finish | `superpowers:finishing-a-development-branch` — merge to main OR open PR (configured per-project in `.claude/settings.json`) |
| master-plan-update | Append "feature X — shipped YYYY-MM-DD" to `docs/features.md` |

`/fix` differs only in that:
- It uses `superpowers:systematic-debugging` instead of brainstorming
- It auto-writes a lesson file at the end (see §6)
- It typically skips master-plan-update (bug fixes don't change features)

## 4. The 6 user-facing commands

| Command | When | Behavior summary |
|---|---|---|
| `/init "<desc>"` | Once per project | Bootstrap: questions → Master Plan → scaffold → `bd init` → first commit |
| `/plan-improve "<change>"` | Iterating Master Plan | Update Master Plan files (no code) |
| `/feature "<desc>"` | New functionality | Full auto pipeline (Mode 2) |
| `/improve "<change to X>"` | Modifying existing behavior | Same pipeline as `/feature`; ground phase emphasizes existing code paths to change |
| `/fix "<bug>"` | Any bug | Debug pipeline + auto-lesson |
| `/lesson` | Rare manual capture | Prompts for trigger/symptom/root_cause/prevention; writes lesson file |

**Anything else is internal.** No `/brainstorm`, `/plan`, `/build`, `/critic`, `/verify`, `/finish` user-facing commands. They exist as private skills the orchestrator invokes.

## 5. Master Plan — split layout

To avoid context overflow on large apps, the Master Plan is **three files** under `docs/`:

| File | Purpose | Size budget |
|---|---|---|
| `docs/architecture.md` | Target architecture: stack, key modules, boundaries, data flow, external services | ≤300 lines |
| `docs/features.md` | Feature list with status: `planned` / `in-progress` / `shipped` / `deprecated` + 1-line description per feature | ≤500 lines |
| `docs/roadmap.md` | Ordered priority list with rationale; what comes next and why | ≤200 lines |

Each pipeline phase loads only the file(s) it needs:

- `ground` loads all three (small enough to fit)
- `brainstorm` loads `architecture.md` + `features.md`
- `critic-1` loads `features.md` + `roadmap.md`
- `master-plan-update` writes only to `features.md`

`/init` creates all three from a template with placeholders. `/plan-improve` updates them. They are committed to git like normal code.

## 6. Lessons system

### Storage

```
.claude/lessons/
  2026-04-25-prisma-migration-rollback.md
  2026-04-26-zod-coerce-vs-transform.md
  ...
```

### Format (every lesson identical)

```markdown
---
trigger: <when this kicks in — e.g. "writing prisma migrations", "using zod with form input">
symptom: <one-line what failed>
root_cause: <why it failed>
prevention: <ONE rule that prevents recurrence>
---

<2-3 sentences of context — enough to remember, not a postmortem>
```

### Application (three layers)

1. **CLAUDE.md** has a directive: "Before writing code in a phase, read `.claude/lessons/` and apply any lesson whose `trigger:` matches the current task description or files in scope."
2. **SessionStart hook** echoes `Lessons learned: N total` so they stay top-of-mind.
3. **Critic agent** explicitly checks the work against the lessons folder at both gates.

### Creation

- `/fix` writes a lesson automatically at the end of debugging. The agent fills the YAML from the debug session: trigger from the task, symptom from the failing test, root_cause from the diagnosis, prevention from the patch.
- `/lesson` prompts the user manually (rare).
- Lessons are never auto-deleted. The user can prune manually.

### Volume control

If `.claude/lessons/` exceeds 50 files, the SessionStart hook prints a notice suggesting consolidation. We do **not** auto-consolidate (loses fidelity).

## 7. Critic agent — `senior-critic`

### File

`.claude/agents/senior-critic.md` — a Claude Code subagent definition.

### Persona

Calm senior engineer. Constructive, not adversarial. Goal: surface what's missing, what's risky, what won't age well. Not a gatekeeper — outputs findings, not approvals.

### Inputs

- Current artifact (spec at gate-1, diff at gate-2)
- `docs/architecture.md` + `docs/features.md`
- `.claude/lessons/` (full)
- The original user request that started the pipeline

### Output format

```markdown
# Critic Review — <gate name> — <ISO date>

## Critical (must address)
- ...

## Important (strongly suggest)
- ...

## Nice to have
- ...

## Lessons applied
- <lesson filename> — <how it applies>

## Lessons NOT applied (and why)
- <lesson filename> — <reason it doesn't apply>
```

### Behavior at gates

- **Gate 1 (post-brainstorm):** reviews the spec. Looks for: unstated assumptions, missing edge cases, scope creep, conflicts with Master Plan, lesson violations.
- **Gate 2 (post-implementation):** reviews the diff. Looks for: missing tests for branches in spec, security holes (auth/input/secrets), error handling gaps, lesson violations.

### What happens with the output

The orchestrator presents the critic's report to the user as a summary (Critical count + Important count + filename of full report saved to `docs/superpowers/critic-reports/`). User has three options:
- `continue` — accept, proceed to next phase
- `address` — orchestrator routes back. **Gate 1 → routes back to brainstorm** with critic findings as additional input. **Gate 2 → routes back to plan** (new tasks created from each Critical/Important finding) and then to TDD for those new tasks
- `override` — user accepts risk, leaves note explaining why; saved to the report

If user does nothing within the message, default is `address` for any Critical findings, `continue` if only Nice-to-have.

## 8. Git automation

The pipeline automates **local** git operations end-to-end (commits, branches, worktrees, merges). The only thing that stays manual is **publishing to a remote** (`git push`). Rationale: pushing is shared-state and the user wants final control; everything else is local mechanics that just slow you down.

| Trigger | Git action | Authored by |
|---|---|---|
| `/init` complete | `git init` + initial commit | pipeline |
| TDD GREEN passes | `git add -A && git commit -m "..."` per task | pipeline |
| Worktree start | `git worktree add` on a new branch | pipeline |
| Feature complete | merge to main OR open PR (per `.claude/settings.json`) | pipeline |
| `/fix` lesson written | included in the fix commit | pipeline |
| Push to remote | **never automatic** — user runs `git push` themselves | user |

Settings.json key (per project):

```json
{ "pipeline": { "finish_mode": "merge" | "pr" } }
```

Default: `merge` (no PR overhead for solo work).

## 9. File layout — `project_template/`

```
project_template/
├── CLAUDE.md                           # rules: pipeline overview, lesson directive, critic protocol
├── .gitignore                          # node_modules, .env, .DS_Store, etc.
├── README.md                           # what this project is, the 6 commands, how to start
├── .claude/
│   ├── settings.json                   # hooks, enabledPlugins, pipeline.finish_mode
│   ├── agents/
│   │   └── senior-critic.md            # critic subagent
│   ├── commands/
│   │   ├── init.md
│   │   ├── plan-improve.md
│   │   ├── feature.md
│   │   ├── improve.md
│   │   ├── fix.md
│   │   └── lesson.md
│   └── lessons/
│       └── .gitkeep                    # empty; populated over time
├── docs/
│   ├── architecture.md                 # template with placeholders, filled by /init
│   ├── features.md                     # template
│   ├── roadmap.md                      # template
│   └── superpowers/
│       ├── specs/                      # per-feature specs land here
│       │   └── .gitkeep
│       └── critic-reports/             # critic output archives
│           └── .gitkeep
└── docs-meta/
    ├── PIPELINE.md                     # human-readable description of the 6 commands and internal flow
    └── LESSON_FORMAT.md                # canonical lesson YAML schema
```

**Starting a new project:**

```bash
cp -r ~/Documents/00_CODE/project_template/ ~/projects/my-new-app
cd ~/projects/my-new-app
claude
> /init "todo app with realtime sync"
```

## 10. CLAUDE.md content (per-project)

Replaces what's currently global. Concrete rules only, no philosophy:

```markdown
# Pipeline rules

This project uses a 6-command AI development pipeline.
Source of truth for the pipeline: docs-meta/PIPELINE.md

## Workflow

User-facing commands (the only commands you should ever ask the user to run):
- /init "<desc>"              — bootstrap (one-time)
- /plan-improve "<change>"    — refine Master Plan
- /feature "<desc>"           — new functionality (full auto pipeline)
- /improve "<change to X>"    — modify existing behavior (full auto pipeline)
- /fix "<bug>"                — debug + auto-lesson
- /lesson                     — manual lesson capture (rare)

Never expose internal phases (brainstorm/plan/build/critic/verify/finish)
to the user as commands. They run automatically inside /feature, /improve, /fix.

## Hard rules

1. No production code without a failing test first.
2. No "done" claim without running the proving command and reading its output.
3. Before writing code: read .claude/lessons/ and apply any lesson whose
   `trigger:` matches the current task or affected files.
4. Before using ANY library/framework: query Context7
   (mcp__plugin_context7-plugin_context7__resolve-library-id then query-docs).
5. Critic runs automatically at gate-1 (post-spec) and gate-2 (post-diff).
   Critical findings block continuation unless user explicitly overrides.
6. Every TDD GREEN cycle ends with a git commit. Every /fix ends with a lesson.

## Master Plan files

- docs/architecture.md — target architecture
- docs/features.md     — feature inventory + status
- docs/roadmap.md      — ordered priorities

Update features.md when a feature ships. Update architecture.md only via /plan-improve.

## Lessons

- Stored in .claude/lessons/
- Format: docs-meta/LESSON_FORMAT.md
- Critic checks every lesson at both gates.
```

## 11. Hooks (`.claude/settings.json`)

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bd prime" },
        { "type": "command", "command": "echo \"Lessons: $(ls .claude/lessons/*.md 2>/dev/null | wc -l | tr -d ' ') | Pipeline: /init /plan-improve /feature /improve /fix /lesson\"" }
      ]}
    ],
    "PreCompact": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bd prime" }
      ]}
    ]
  },
  "pipeline": { "finish_mode": "merge" },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "beads@beads-marketplace": true,
    "template-bridge@template-bridge-marketplace": true,
    "context7-plugin@context7-marketplace": true
  }
}
```

## 12. Internal-phase implementation

Each user-facing command is a slash-command file in `.claude/commands/<name>.md`. Each file is an instruction document the agent reads and executes top-to-bottom. The orchestration logic lives in those files, not in code.

Example skeleton for `/feature.md`:

```markdown
---
description: New functionality — full auto pipeline
---

# /feature pipeline

Input: $ARGUMENTS (the feature description)

Execute these phases in order. Do NOT prompt the user between phases unless
the critic surfaces Critical findings or the brainstorm needs a clarifying question.

## Phase 1: ground
- Read docs/architecture.md, docs/features.md, docs/roadmap.md
- Read every file in .claude/lessons/
- Detect libraries from package manifests; for each, run mcp__...resolve-library-id then query-docs
- Summarize findings in 5-10 bullets

## Phase 2: brainstorm
- Invoke superpowers:brainstorming with the user input + ground summary
- Output: spec saved to docs/superpowers/specs/YYYY-MM-DD-<slug>.md

## Phase 3: critic-1
- Invoke .claude/agents/senior-critic.md with: spec, features.md, roadmap.md, all lessons
- Save report to docs/superpowers/critic-reports/YYYY-MM-DD-<slug>-gate1.md
- If Critical findings: present to user, await continue/address/override
- Otherwise: proceed silently with one-line summary

## Phase 4: plan
- Invoke superpowers:writing-plans on the spec
- For each task in plan: bd create + bd dep add (sequence)

## Phase 5: worktree (conditional)
- If number of tasks > 3: invoke superpowers:using-git-worktrees

## Phase 6: TDD loop
For each bd-ready task:
  - Invoke superpowers:test-driven-development
  - After GREEN: git add -A && git commit -m "<task title>"
  - bd close <id>

## Phase 7: critic-2
- Invoke senior-critic on the cumulative diff vs base branch
- Save report; same continue/address/override gate

## Phase 8: verify
- Invoke superpowers:verification-before-completion

## Phase 9: finish
- Read .claude/settings.json pipeline.finish_mode
- merge: git merge worktree branch into main, delete worktree
- pr: gh pr create with critic summary in body

## Phase 10: master-plan-update
- Append entry to docs/features.md under "Shipped"
- git commit -m "docs: feature X shipped"
```

`/improve.md` is the same except Phase 1 emphasizes "find the existing code paths that implement <X>" and the spec phase frames the work as a behavior change.

`/fix.md` is the same except brainstorm is replaced by `superpowers:systematic-debugging`, and Phase 10 is replaced by lesson-write.

## 13. Edge cases & error handling

| Situation | Behavior |
|---|---|
| `/init` in a non-empty folder | Refuse. Tell user to use empty folder or `--force` flag |
| `/feature` before `/init` (no Master Plan exists) | Refuse. Tell user to run `/init` first |
| Context7 lookup fails (offline / lib not on Context7) | Log warning, continue with note in spec "library docs unavailable, proceed with caution" |
| Critic gate-1 has Critical findings, user picks `address` | Re-run brainstorm with critic findings as additional input |
| TDD test never reaches GREEN after 3 attempts | Stop the loop, surface to user, do NOT silently move on |
| Verify command exits non-zero | Stop the pipeline, surface output, do NOT claim done |
| `bd init` already done (re-running `/init`) | Skip Beads init, continue with rest of bootstrap |
| Lesson file has malformed YAML | Log warning, continue (lessons are advisory, not blocking) |

## 14. Acceptance criteria

The design is implemented correctly when:

1. `cp -r project_template/ ~/projects/foo && cd ~/projects/foo && claude` → `/init "todo app"` produces:
   - Filled `docs/architecture.md`, `docs/features.md`, `docs/roadmap.md`
   - Initialized git + first commit
   - Initialized Beads
   - No feature code

2. `/feature "add user signup"` runs end-to-end without user input EXCEPT when the brainstorm has a real clarifying question or the critic surfaces a Critical finding.

3. `/fix "login redirect loops"` ends with a new file under `.claude/lessons/` whose `trigger:` could match a future task.

4. After 3 features and 2 fixes, `.claude/lessons/` has 2 lesson files, the critic references at least one of them in a subsequent gate report, and `docs/features.md` lists 3 shipped features.

5. The user typed only the 6 commands. They never typed `/brainstorm`, `/plan`, `/build`, `/critic`, `/verify`, or `/finish`.

## 15. Open questions (defer to implementation plan)

- Should the orchestrator stream phase progress to the user (e.g. "Phase 3/10: critic gate 1...") or stay silent until done?
- Where exactly should critic-reports live? `docs/` is committed; some users may want them in `.claude/` (gitignored).
- How verbose should the critic be — full markdown report saved to file always, or only when Critical/Important findings exist?
- Should `/improve` be allowed to add NEW features, or strictly limited to behavior changes? (Currently: strictly behavior changes; new features go through `/feature`.)

These are intentionally left for the implementation plan, not the spec.

## 16. Out of scope (explicit non-asks)

- Cross-agent compatibility (Cursor/Copilot/Windsurf)
- Public marketplace for skills/lessons
- Visual project dashboard
- Multi-developer coordination
- LLM-driven code review of pull requests on GitHub (use the existing `gh pr review` tooling for that)
- Auto-deploying anything anywhere
- Replacing Beads with a custom tracker
