# AI Development Pipeline — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform `~/Documents/00_CODE/project_template/` from two reference markdown files into a real copy-paste starter kit that ships a 6-command AI development pipeline (`/init`, `/plan-improve`, `/feature`, `/improve`, `/fix`, `/lesson`) with an automatic senior-critic agent at two gates and a lessons-learned flywheel.

**Architecture:** Each user-facing command is a single Markdown slash-command file under `.claude/commands/` that orchestrates internal phases (ground → brainstorm → critic-1 → plan → TDD → critic-2 → verify → finish) by invoking existing Superpowers/Beads/Context7 skills. State lives in committed files (`docs/architecture.md`, `docs/features.md`, `docs/roadmap.md`, `.claude/lessons/*.md`, `docs/superpowers/critic-reports/*.md`).

**Tech Stack:** Markdown command files, JSON settings, Claude Code subagents, Superpowers plugin, Beads CLI, Context7 MCP. No new code in any programming language — this is a pipeline assembled from configuration and prompt instructions.

**Reference spec:** `docs/superpowers/specs/2026-04-25-ai-pipeline-design.md`

---

## File structure to be produced

After this plan completes, `project_template/` will look like:

```
project_template/
├── CLAUDE.md                                # NEW (replaces nothing — supplements existing markdown)
├── .gitignore                               # NEW
├── README.md                                # NEW (project-level instructions)
├── .claude/
│   ├── settings.json                        # NEW
│   ├── agents/
│   │   └── senior-critic.md                 # NEW
│   ├── commands/
│   │   ├── init.md                          # NEW
│   │   ├── plan-improve.md                  # NEW
│   │   ├── feature.md                       # NEW
│   │   ├── improve.md                       # NEW
│   │   ├── fix.md                           # NEW
│   │   └── lesson.md                        # NEW
│   └── lessons/
│       └── .gitkeep                         # NEW
├── docs/
│   ├── architecture.md                      # NEW (template with placeholders)
│   ├── features.md                          # NEW (template)
│   ├── roadmap.md                           # NEW (template)
│   └── superpowers/
│       ├── specs/                           # already exists; add .gitkeep
│       │   ├── .gitkeep                     # NEW
│       │   └── 2026-04-25-ai-pipeline-design.md  # already exists
│       ├── plans/                           # already exists
│       │   └── 2026-04-25-ai-pipeline-implementation.md  # this file
│       └── critic-reports/
│           └── .gitkeep                     # NEW
├── docs-meta/
│   ├── PIPELINE.md                          # NEW
│   └── LESSON_FORMAT.md                     # NEW
├── CLAUDE_CODE_SETUP.md                     # KEEP (historical reference)
└── CLAUDE_CODE_WORKFLOW_GUIDE_RU.md         # KEEP (historical reference)
```

The two existing `CLAUDE_CODE_*.md` files stay where they are — they're install reference docs, not part of the per-project template runtime. They will not be copied with `cp -r` into a new project (we'll exclude them via README guidance).

---

## Verification approach

This is a meta-engineering task — the artifacts are configuration and prompt files, not application code. "Tests" therefore mean **structural verification**: does the file exist, does it contain the required sections, is the JSON valid, does the slash-command frontmatter parse, etc. Each task includes the exact verification commands.

The end-to-end test (Task 17) actually copies the template into `/tmp` and runs `/init` to verify the bootstrap path works.

---

## Task 1: Create directory skeleton + .gitkeep files

**Files:**
- Create: `.claude/agents/.gitkeep`
- Create: `.claude/commands/.gitkeep`
- Create: `.claude/lessons/.gitkeep`
- Create: `docs/superpowers/specs/.gitkeep`
- Create: `docs/superpowers/critic-reports/.gitkeep`
- Create: `docs-meta/.gitkeep`

- [ ] **Step 1: Create directories and gitkeep markers**

```bash
cd /Users/vladislav/Documents/00_CODE/project_template
mkdir -p .claude/agents .claude/commands .claude/lessons \
         docs/superpowers/specs docs/superpowers/critic-reports \
         docs-meta
touch .claude/agents/.gitkeep \
      .claude/commands/.gitkeep \
      .claude/lessons/.gitkeep \
      docs/superpowers/specs/.gitkeep \
      docs/superpowers/critic-reports/.gitkeep \
      docs-meta/.gitkeep
```

- [ ] **Step 2: Verify all directories exist**

Run:
```bash
find /Users/vladislav/Documents/00_CODE/project_template -type d | sort
```

Expected output includes:
```
.../project_template/.claude
.../project_template/.claude/agents
.../project_template/.claude/commands
.../project_template/.claude/lessons
.../project_template/docs
.../project_template/docs/superpowers
.../project_template/docs/superpowers/critic-reports
.../project_template/docs/superpowers/plans
.../project_template/docs/superpowers/specs
.../project_template/docs-meta
```

- [ ] **Step 3: Commit (skip — no git yet)**

This directory is not under git. Skip commit. (Note: when this template is copied to a new project, `/init` will run `git init` and commit everything in one go.)

---

## Task 2: Write `.gitignore`

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Write the failing test (verification)**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.gitignore && echo PASS || echo FAIL
```
Expected initially: `FAIL`

- [ ] **Step 2: Write the file**

Content for `.gitignore`:
```
# OS
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
*.swp
*~

# Dependencies
node_modules/
.venv/
__pycache__/
*.pyc

# Build
dist/
build/
*.egg-info/

# Environment / secrets
.env
.env.local
.env.*.local
*.pem
*.key

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Beads
.beads/cache/

# Test coverage
coverage/
.coverage
htmlcov/

# Claude Code session-local
.claude/cache/
```

- [ ] **Step 3: Verify**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.gitignore && echo PASS
grep -q "^.env$" /Users/vladislav/Documents/00_CODE/project_template/.gitignore && echo "secrets ignored"
grep -q "^node_modules/$" /Users/vladislav/Documents/00_CODE/project_template/.gitignore && echo "deps ignored"
```
Expected: `PASS` + `secrets ignored` + `deps ignored`

- [ ] **Step 4: Commit (skip)**

---

## Task 3: Write `.claude/settings.json`

**Files:**
- Create: `.claude/settings.json`

This is the per-project settings file — separate from the user-global `~/.claude/settings.json`. It declares hooks, enabled plugins, and the `pipeline.finish_mode`.

- [ ] **Step 1: Write the failing test**

```bash
python3 -c "import json; json.load(open('/Users/vladislav/Documents/00_CODE/project_template/.claude/settings.json'))" 2>&1 | head -1
```
Expected initially: error (file not found).

- [ ] **Step 2: Write the file**

Content for `.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bd prime 2>/dev/null || true" },
          { "type": "command", "command": "echo \"Lessons: $(ls .claude/lessons/*.md 2>/dev/null | wc -l | tr -d ' ') | Pipeline: /init /plan-improve /feature /improve /fix /lesson\"" }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bd prime 2>/dev/null || true" }
        ]
      }
    ]
  },
  "pipeline": {
    "finish_mode": "merge"
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "beads@beads-marketplace": true,
    "template-bridge@template-bridge-marketplace": true,
    "context7-plugin@context7-marketplace": true
  }
}
```

Notes:
- `bd prime 2>/dev/null || true` — fails silently if Beads not initialized yet (e.g. before `/init` runs)
- `pipeline.finish_mode: "merge"` is the default; user changes to `"pr"` per project if they want PRs

- [ ] **Step 3: Verify**

```bash
python3 -c "
import json
s = json.load(open('/Users/vladislav/Documents/00_CODE/project_template/.claude/settings.json'))
assert 'hooks' in s and 'SessionStart' in s['hooks'], 'missing SessionStart hook'
assert 'PreCompact' in s['hooks'], 'missing PreCompact hook'
assert s['pipeline']['finish_mode'] in ('merge', 'pr'), 'bad finish_mode'
assert 'superpowers@claude-plugins-official' in s['enabledPlugins'], 'superpowers not enabled'
print('PASS')
"
```
Expected: `PASS`

- [ ] **Step 4: Commit (skip)**

---

## Task 4: Write per-project `CLAUDE.md`

**Files:**
- Create: `CLAUDE.md`

Note: this `CLAUDE.md` is the per-project file shipped with the template. It is distinct from the user-global `~/.claude/CLAUDE.md`. When a developer copies the template to a new project, this file lands in the project root and is loaded automatically by Claude Code.

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/CLAUDE.md && echo EXISTS || echo MISSING
```
Expected initially: `MISSING`

- [ ] **Step 2: Write the file**

Content for `CLAUDE.md`:
```markdown
# Pipeline rules

This project uses a 6-command AI development pipeline.
Source of truth: `docs-meta/PIPELINE.md`.

## User-facing commands (the only commands you should ever ask the user to run)

| Command | When |
|---|---|
| `/init "<desc>"` | Bootstrap (one-time per project) |
| `/plan-improve "<change>"` | Refine the Master Plan (no code) |
| `/feature "<desc>"` | New functionality — full automatic pipeline |
| `/improve "<change to X>"` | Modify existing behavior — full automatic pipeline |
| `/fix "<bug>"` | Debug + auto-record lesson |
| `/lesson` | Manually record a lesson (rare) |

**Never expose internal phases** (`/brainstorm`, `/plan`, `/build`, `/critic`, `/verify`, `/finish`) to the user as commands. They run automatically inside `/feature`, `/improve`, `/fix`.

## Hard rules

1. **No production code without a failing test first.** Write the test, watch it fail for the right reason, then write code.
2. **No "done" claim without running the proving command and reading its output.** Evidence before assertions.
3. **Before writing code in any phase:** read every file under `.claude/lessons/` and apply any lesson whose `trigger:` matches the current task description or the files in scope. Cite the lesson filename in the implementation when you apply it.
4. **Before using ANY library, framework, SDK, or CLI tool:** query Context7. Run `mcp__plugin_context7-plugin_context7__resolve-library-id` then `mcp__plugin_context7-plugin_context7__query-docs`. Do not write library code from memory.
5. **Critic runs automatically** at gate-1 (post-spec) and gate-2 (post-diff). Critical findings block continuation unless the user explicitly overrides with a written reason saved to the report.
6. **Every TDD GREEN cycle ends with a `git commit`.** Every `/fix` ends with a lesson written to `.claude/lessons/`.

## Master Plan files

The "Master Plan" is split across three files to keep each one within context budget:

- `docs/architecture.md` — target architecture (≤300 lines)
- `docs/features.md` — feature inventory + status (≤500 lines)
- `docs/roadmap.md` — ordered priorities (≤200 lines)

Update `features.md` automatically when a feature ships (final phase of `/feature` and `/improve`). Update `architecture.md` and `roadmap.md` only via `/plan-improve` — never silently.

## Lessons

- Stored in `.claude/lessons/` as one markdown file per lesson
- Schema: `docs-meta/LESSON_FORMAT.md`
- Critic agent reads them at every gate and explicitly cites which apply
- Never auto-delete; user prunes manually

## Git

- Pipeline automates: `init`, `add`, `commit`, branch creation, `worktree`, local merge
- Pipeline does NOT automate: `git push` (always manual — user controls remote)

## Plugins (assumed installed)

- `superpowers` — TDD, brainstorming, debugging, verification, code-review, worktrees, finishing
- `beads` — persistent task tracking across sessions
- `template-bridge` — 413+ specialist agent templates on demand
- `context7-plugin` — live library docs

If any are missing, the orchestrator should warn but continue with degraded behavior.
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/CLAUDE.md
test -f "$F" && echo EXISTS
grep -q "^| \`/init" "$F" && echo "init listed"
grep -q "^| \`/feature" "$F" && echo "feature listed"
grep -q "Hard rules" "$F" && echo "hard rules section"
grep -q "Lessons" "$F" && echo "lessons section"
grep -q "git push" "$F" && echo "git push policy"
```
Expected: `EXISTS` + all 5 confirmation lines.

- [ ] **Step 4: Commit (skip)**

---

## Task 5: Write `docs/architecture.md` template

**Files:**
- Create: `docs/architecture.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/docs/architecture.md && echo EXISTS || echo MISSING
```
Expected initially: `MISSING`

- [ ] **Step 2: Write the file**

Content for `docs/architecture.md`:
```markdown
# Architecture

> **Template note:** `/init` fills this in based on the app description and clarifying questions. `/plan-improve` updates it. Do NOT edit manually inside Claude — go through `/plan-improve` so the change is reviewed by the critic.

**Status:** UNFILLED — run `/init "<app description>"` to populate.

---

## 1. What this app is

<one paragraph: the app's purpose, target user, and the single problem it solves>

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language(s) | <e.g. TypeScript> | <reason> |
| Framework | <e.g. Next.js 15> | <reason> |
| Database | <e.g. PostgreSQL via Prisma> | <reason> |
| Auth | <e.g. NextAuth> | <reason> |
| Hosting | <e.g. Vercel + Supabase> | <reason> |
| Testing | <e.g. Vitest + Playwright> | <reason> |

## 3. Key modules / boundaries

<bullet list of top-level modules, one line each: name, purpose, depends-on>

Example shape:
- `api/` — REST endpoints; depends on `db/`, `auth/`
- `db/` — schema + migrations; depends on nothing
- `auth/` — JWT verification; depends on `db/`
- `ui/` — React components; depends on `api/`

## 4. Data flow

<2-5 sentences describing how a typical request moves through the system>

## 5. External services

| Service | Purpose | Auth method |
|---|---|---|
| <e.g. Stripe> | <e.g. payments> | <e.g. API key in env> |

## 6. Hard architectural constraints

<bullet list of things that MUST be true — security, compliance, performance budgets. Empty is OK.>

---

**Soft size budget for this file:** 300 lines. If you exceed it, that's a signal the architecture is fragmenting — split a sub-system into its own document and link to it from here.
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/docs/architecture.md
test -f "$F" && echo EXISTS
grep -q "Template note" "$F" && echo "marked as template"
grep -q "UNFILLED" "$F" && echo "status placeholder present"
wc -l "$F" | awk '{print "lines:", $1}'
```
Expected: `EXISTS` + both confirmations + line count.

- [ ] **Step 4: Commit (skip)**

---

## Task 6: Write `docs/features.md` template

**Files:**
- Create: `docs/features.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/docs/features.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `docs/features.md`:
```markdown
# Features

> **Template note:** `/init` populates the initial planned features. `/feature` and `/improve` update this file (move feature from Planned → Shipped) at their final phase. `/plan-improve` adds new features to Planned.

**Format per feature (one line each):**
`- [ID] <slug> — <one-line description> — <status: planned|in-progress|shipped|deprecated>`

---

## Planned

- [ ] <none yet — populated by /init>

## In progress

- [ ] <none yet — moved here automatically when a /feature run starts>

## Shipped

- [ ] <none yet — moved here automatically by the pipeline's master-plan-update phase>

## Deprecated

- [ ] <none yet — manual move when removing a feature>

---

**Soft size budget for this file:** 500 lines. If exceeded, archive deprecated entries to `docs/features-archive.md` and link from here.
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/docs/features.md
test -f "$F" && echo EXISTS
grep -q "^## Planned" "$F" && echo "planned section"
grep -q "^## Shipped" "$F" && echo "shipped section"
grep -q "^## Deprecated" "$F" && echo "deprecated section"
```
Expected: `EXISTS` + all three section confirmations.

- [ ] **Step 4: Commit (skip)**

---

## Task 7: Write `docs/roadmap.md` template

**Files:**
- Create: `docs/roadmap.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/docs/roadmap.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `docs/roadmap.md`:
```markdown
# Roadmap

> **Template note:** `/init` writes the initial roadmap. `/plan-improve` is the only command that updates this file. Critic reviews changes.

The roadmap answers: **what comes next, and why?** Order matters; the top item is the next thing to build.

---

## Now (next 1-3 features)

1. <feature-slug> — <one sentence on why this is next>
2. <feature-slug> — <one sentence>
3. <feature-slug> — <one sentence>

## Next (1-3 features after Now)

- <feature-slug> — <reason>

## Later (eventually, no commitment)

- <feature-slug> — <reason>

## Explicitly NOT doing (and why)

- <feature-slug> — <one sentence on why we're not building this>

---

**Soft size budget:** 200 lines. The roadmap should be short. If it grows past 200 lines, you have a backlog, not a roadmap — move long-tail items to `docs/backlog.md`.
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/docs/roadmap.md
test -f "$F" && echo EXISTS
for s in "Now" "Next" "Later" "Explicitly NOT doing"; do
  grep -q "^## $s" "$F" && echo "section: $s OK"
done
```
Expected: `EXISTS` + 4 section confirmations.

- [ ] **Step 4: Commit (skip)**

---

## Task 8: Write `docs-meta/PIPELINE.md`

**Files:**
- Create: `docs-meta/PIPELINE.md`

This is the human-readable description of the full pipeline. It is the source of truth `CLAUDE.md` points to.

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/docs-meta/PIPELINE.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `docs-meta/PIPELINE.md`:
```markdown
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
| `/init` in non-empty folder | Refuse with explanation; suggest empty folder or `--force` |
| `/feature` before `/init` (no Master Plan) | Refuse; tell user to run `/init` first |
| Context7 lookup fails | Log warning, continue, note in spec "library docs unavailable, proceed with caution" |
| Critic gate-1 Critical + user picks `address` | Re-run brainstorm with critic findings injected |
| Critic gate-2 Critical + user picks `address` | Re-run plan with critic findings → new tasks → TDD loop on new tasks |
| TDD test never reaches GREEN after 3 attempts | Stop loop, surface to user, do NOT silently continue |
| Verify command exits non-zero | Stop pipeline, surface output, do NOT claim done |
| `bd init` already done | Skip; continue with rest of bootstrap |
| Lesson file has malformed YAML | Log warning, continue (lessons are advisory) |
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/docs-meta/PIPELINE.md
test -f "$F" && echo EXISTS
for cmd in init plan-improve feature improve fix lesson; do
  grep -q "/$cmd" "$F" && echo "documents: /$cmd"
done
grep -q "Internal phases" "$F" && echo "internal phases section"
grep -q "Critic protocol" "$F" && echo "critic protocol section"
grep -q "Git policy" "$F" && echo "git policy section"
grep -q "Edge cases" "$F" && echo "edge cases section"
```
Expected: `EXISTS` + all 6 commands documented + 4 section confirmations.

- [ ] **Step 4: Commit (skip)**

---

## Task 9: Write `docs-meta/LESSON_FORMAT.md`

**Files:**
- Create: `docs-meta/LESSON_FORMAT.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/docs-meta/LESSON_FORMAT.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `docs-meta/LESSON_FORMAT.md`:
```markdown
# Lesson file format

Every file under `.claude/lessons/` MUST follow this exact shape so the critic agent and ground phase can parse them automatically.

## Filename

`YYYY-MM-DD-<short-slug>.md`

Examples:
- `2026-04-25-prisma-migration-rollback.md`
- `2026-04-26-zod-coerce-vs-transform.md`
- `2026-05-01-nextjs-app-router-revalidate.md`

The slug should be 3-6 words separated by hyphens, describing the topic — not the symptom.

## Required structure

```markdown
---
trigger: <one phrase describing WHEN this lesson applies — e.g. "writing prisma migrations", "using zod with form input", "next.js server actions">
symptom: <one line — what visibly broke>
root_cause: <one line — the actual reason>
prevention: <ONE rule that prevents recurrence — short, imperative>
---

<2-3 sentences of context. Enough for a future-you to recognize the situation.
NOT a postmortem. NOT a long-form story. Keep it tight.>
```

## Field rules

| Field | Required | Rule |
|---|---|---|
| `trigger` | yes | A phrase that the agent can substring-match against future task descriptions or file paths. Be specific enough that it doesn't fire on every task, broad enough that it fires when relevant. |
| `symptom` | yes | What you (or a test, or the user) saw fail. Past tense. |
| `root_cause` | yes | The actual reason — not the symptom. If you wrote "test failed" here, you didn't dig deep enough. |
| `prevention` | yes | An imperative rule. Starts with a verb. "Always X" or "Never Y" or "Before doing X, check Y". |

## Body rules

- 2-3 sentences. Hard limit.
- Past tense for the situation, present tense for the rule.
- No code blocks unless they're a 1-2 line snippet that demonstrates the trap.
- No links to external issues unless absolutely necessary (links rot).

## Example

```markdown
---
trigger: writing prisma migrations on tables with existing data
symptom: migration succeeded locally, failed in production with NOT NULL constraint violation
root_cause: prisma generated a migration with NOT NULL but no default value; local DB was empty so it passed; prod had millions of rows
prevention: Always inspect generated SQL for NOT NULL columns added without DEFAULT. If found, edit the migration to backfill before applying the constraint.
---

We added a `last_seen_at` column to `users`. Prisma's autogenerated migration was a single ALTER TABLE with NOT NULL and no DEFAULT. Worked in dev (empty table), broke prod. Fix was a 3-step migration: add nullable, backfill, then add NOT NULL.
```

## Anti-patterns

- ❌ `trigger: "bugs"` — too broad, fires on everything
- ❌ `trigger: "the specific bug we hit on April 25 in commit abc123"` — too narrow, never fires again
- ❌ `prevention: "be more careful"` — not actionable
- ❌ Body longer than 5 sentences — that's a postmortem; put it in `docs/postmortems/` and link if needed
- ❌ Multiple lessons in one file — one lesson per file, always
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/docs-meta/LESSON_FORMAT.md
test -f "$F" && echo EXISTS
for field in trigger symptom root_cause prevention; do
  grep -q "$field" "$F" && echo "documents field: $field"
done
grep -q "Anti-patterns" "$F" && echo "anti-patterns section"
```
Expected: `EXISTS` + 4 fields documented + anti-patterns section.

- [ ] **Step 4: Commit (skip)**

---

## Task 10: Write `.claude/agents/senior-critic.md`

**Files:**
- Create: `.claude/agents/senior-critic.md`

This is a Claude Code subagent definition. Format follows the `.claude/agents/` convention with frontmatter.

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.claude/agents/senior-critic.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `.claude/agents/senior-critic.md`:
```markdown
---
name: senior-critic
description: Use at gate-1 (post-spec) and gate-2 (post-implementation). Calmly identifies risks, surfaces missing edge cases, flags omissions and lesson violations. Constructive senior-engineer tone — not adversarial. Outputs findings, never approvals or rejections.
tools: Read, Grep, Glob, Bash
---

# Senior Critic

You are a calm senior engineer reviewing work in progress. You are NOT a gatekeeper. You produce findings; the user decides what to do with them.

## Your two gates

You will be invoked at one of two gates. The orchestrator tells you which.

### Gate 1: post-brainstorm (reviewing a spec)

You receive:
- The spec file (path provided in your prompt)
- `docs/architecture.md`, `docs/features.md`, `docs/roadmap.md`
- All files under `.claude/lessons/`
- The original user request that started the pipeline

Look for:
- Unstated assumptions ("the spec assumes X without justification — verify")
- Missing edge cases (auth failures, empty inputs, concurrent writes, network errors, partial state)
- Scope creep beyond the user request
- Conflicts with the Master Plan (architecture violations, conflicts with shipped features, items not in roadmap)
- Lesson violations (any lesson whose `trigger:` matches this spec's domain)
- Test plan gaps (what behaviors are claimed but not tested?)

### Gate 2: post-implementation (reviewing a diff)

You receive:
- The base branch and the head branch (run `git diff base..head` to see the change)
- The spec it was built from
- `docs/architecture.md`, `docs/features.md`
- All files under `.claude/lessons/`

Look for:
- Behaviors claimed in the spec but missing in the code or tests
- Security issues (auth bypass, input validation, secret leakage, injection vectors, missing rate limits)
- Error handling gaps (try/except swallowing details, missing retries, no fallback path)
- Lesson violations (cite the lesson filename)
- Tests that pass but don't actually exercise the claimed behavior (assertion-on-self, mocked the thing under test, etc.)
- Architecture drift (new dependencies not justified, boundaries crossed, modules now too large)

## Tone

- Constructive. State the risk; don't moralize.
- Specific. "The spec doesn't define what happens when X" — not "this is incomplete".
- Cite evidence. Quote the file:line, the spec section, or the lesson filename.
- No qualifier hedging ("might", "could possibly", "perhaps consider"). Either it's a finding or it isn't.

## Output format

Save your report to: `docs/superpowers/critic-reports/YYYY-MM-DD-<slug>-gate{1,2}.md` (the orchestrator tells you the slug and gate number).

Use this exact structure:

```markdown
# Critic Review — Gate {1|2} — <ISO date>

**Subject:** <spec filename or diff range>
**Reviewed against:** docs/architecture.md, docs/features.md, .claude/lessons/ (N files)

## Critical (must address before proceeding)
- [finding 1] — evidence: <file:line or spec §>
- ...

(If none: "None.")

## Important (strongly suggest addressing)
- [finding 1] — evidence: ...
- ...

(If none: "None.")

## Nice to have
- [finding 1] — ...
- ...

(If none: "None.")

## Lessons applied
- `<lesson-filename>` — <how it applied to this work>
- ...

(If none: "None matched the trigger of any lesson.")

## Lessons NOT applied (and why)
- `<lesson-filename>` — <one sentence: why this didn't apply>
- ...

(Only list lessons whose trigger plausibly matched but you decided didn't apply on inspection. Skip ones that obviously don't apply.)
```

## Reporting back to the orchestrator

After saving the file, return a one-line summary in this exact shape:

```
critic gate {1|2}: {N_critical} Critical / {N_important} Important / {N_nice} Nice-to-have. Report: <path-to-report-file>
```

Do not output the full report inline — the orchestrator will read the file and decide what to show the user.

## What you do NOT do

- You do not approve or reject work. You produce findings.
- You do not propose fixes. You point at problems; the orchestrator routes back to brainstorm or plan.
- You do not modify any code. Read-only.
- You do not invent constraints. If the spec doesn't say it must be X, don't critique the absence of X unless a lesson says so.
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/.claude/agents/senior-critic.md
test -f "$F" && echo EXISTS
grep -q "^name: senior-critic$" "$F" && echo "frontmatter name OK"
grep -q "^description:" "$F" && echo "frontmatter description OK"
grep -q "^tools:" "$F" && echo "frontmatter tools OK"
grep -q "Gate 1: post-brainstorm" "$F" && echo "gate 1 documented"
grep -q "Gate 2: post-implementation" "$F" && echo "gate 2 documented"
grep -q "## Critical" "$F" && echo "output format defined"
```
Expected: `EXISTS` + all 5 confirmations.

- [ ] **Step 4: Commit (skip)**

---

## Task 11: Write `.claude/commands/init.md`

**Files:**
- Create: `.claude/commands/init.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.claude/commands/init.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `.claude/commands/init.md`:
```markdown
---
description: Bootstrap a new project — fills Master Plan, scaffolds skeleton, runs git init + bd init, makes first commit. Run once per project.
argument-hint: "<one-line app description>"
---

# /init — bootstrap a new project

**Input:** `$ARGUMENTS` (the one-line app description)

## Pre-flight

1. **Check folder is empty enough.**
   - Run: `ls -A | grep -v -E "^(\.git|\.claude|docs|docs-meta|CLAUDE\.md|README\.md|\.gitignore)$" | head`
   - If any unexpected files exist (source code, package.json, etc.) → STOP. Print: "Folder is not empty. Use an empty folder, or run `/init` with `--force` (not yet supported)."

2. **Check Master Plan files have not been filled in already.**
   - Run: `grep -q "UNFILLED" docs/architecture.md 2>/dev/null && echo unfilled || echo filled`
   - If `filled` → STOP. Print: "This project is already initialized. Use `/plan-improve` to refine the plan."

If both checks pass, proceed.

## Phase 1: Clarify

Ask the user **exactly 3 questions** (no more, no fewer). Multiple-choice when possible. Examples:

1. "What's the primary tech stack? A) Next.js + TypeScript + Postgres B) Python (FastAPI/Django) C) Go D) Other (specify)"
2. "Who is the primary user? A) End consumer B) Developer/technical user C) Internal team D) Other"
3. "What's the single most important quality constraint? A) Speed to ship B) Security/compliance C) Performance D) Maintainability"

Wait for answers before proceeding.

## Phase 2: Fill Master Plan

Based on the description and the 3 answers, write three files. Use the templates as the starting structure but **replace every placeholder**.

1. `docs/architecture.md` — fill sections 1-6 with concrete content. Tech stack table populated. Module list with 3-7 entries. Data flow paragraph. External services if any. Hard constraints from answer #3.

2. `docs/features.md` — list 5-8 initial features under "Planned". Each line: `- [ ] [F-001] <slug> — <one-line description> — planned`. Number IDs sequentially (F-001, F-002, ...).

3. `docs/roadmap.md` — under "Now": top 3 features from features.md with one-sentence rationale each. Under "Next": features 4-6. Under "Later": features 7-8. Under "Explicitly NOT doing": leave 1-2 honest entries (things the user might reasonably ask for but shouldn't be in v1).

## Phase 3: Scaffold

Based on the chosen tech stack, create the minimum project skeleton. Examples:

**Next.js + TypeScript:**
```bash
# Use create-next-app interactively? No — too many prompts. Use a minimal scaffold:
mkdir -p src/app src/lib src/components tests
# Write minimal package.json, tsconfig.json, next.config.js
```

**Python:**
```bash
mkdir -p src tests
# Write pyproject.toml with chosen framework, .python-version, src/__init__.py
```

**Go:**
```bash
mkdir -p cmd internal pkg
go mod init <project-name>
```

For each scaffolded file, use Context7 to verify current best practices BEFORE writing:
```
mcp__plugin_context7-plugin_context7__resolve-library-id { libraryName: "<lib>" }
mcp__plugin_context7-plugin_context7__query-docs { id: "<resolved>", topic: "minimal project setup" }
```

Do NOT install dependencies (no `npm install`, no `pip install`). Just write the manifests. The user runs install themselves.

## Phase 4: Initialize Beads

Run:
```bash
bd init
```

If `bd init` fails (already initialized), continue silently.

Then create one epic placeholder:
```bash
bd create -t epic "Initial development of <app name>"
```

## Phase 5: Initialize git + first commit

```bash
git init
git add -A
git commit -m "chore: initial scaffold via /init

App: <description>
Stack: <chosen stack>
Pipeline: 6-command AI development pipeline (see docs-meta/PIPELINE.md)"
```

If `git init` fails because the folder is already a git repo, skip the init but still add+commit (with message "chore: pipeline scaffold").

## Phase 6: Report and hand off

Print a structured summary:

```
✓ Bootstrap complete.

Wrote:
  - docs/architecture.md (filled)
  - docs/features.md (8 planned features)
  - docs/roadmap.md (3-now, 3-next, 2-later)
  - <scaffolded source files>

Initialized:
  - git (first commit: <sha>)
  - beads (epic: <epic-id>)

Next steps:
  1. Review docs/architecture.md, docs/features.md, docs/roadmap.md
  2. If anything is wrong: /plan-improve "<change>"
  3. When ready to build: /feature "<first feature description>"
```

## Error handling

| Failure | Action |
|---|---|
| User declines to answer the 3 questions | Stop. Tell user `/init` requires answers to all 3. |
| Context7 unavailable | Continue with stack-default scaffolding; print warning. |
| `git init` fails (not because of existing repo) | Stop. Surface error. Do NOT proceed. |
| `bd` command not found | Print warning: "Beads not installed; task tracking will be disabled. Continue without `bd`." Then continue. |
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands/init.md
test -f "$F" && echo EXISTS
grep -q "^description:" "$F" && echo "has description frontmatter"
grep -q '\$ARGUMENTS' "$F" && echo "uses $ARGUMENTS"
for phase in "Pre-flight" "Phase 1" "Phase 2" "Phase 3" "Phase 4" "Phase 5" "Phase 6"; do
  grep -q "$phase" "$F" && echo "phase: $phase OK"
done
grep -q "git init" "$F" && echo "git init step present"
grep -q "bd init" "$F" && echo "bd init step present"
```
Expected: `EXISTS` + frontmatter checks + 7 phase checks + git/bd checks.

- [ ] **Step 4: Commit (skip)**

---

## Task 12: Write `.claude/commands/plan-improve.md`

**Files:**
- Create: `.claude/commands/plan-improve.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.claude/commands/plan-improve.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `.claude/commands/plan-improve.md`:
```markdown
---
description: Refine the Master Plan (architecture / features / roadmap) without writing any feature code. Critic-reviewed.
argument-hint: "<change to make to the plan>"
---

# /plan-improve — refine the Master Plan

**Input:** `$ARGUMENTS` (description of the change to the plan)

## Pre-flight

- Run: `grep -q "UNFILLED" docs/architecture.md 2>/dev/null && echo unfilled || echo filled`
- If `unfilled` → STOP. Print: "Master Plan not initialized. Run `/init \"<app description>\"` first."

## Phase 1: Load current state

Read in full:
- `docs/architecture.md`
- `docs/features.md`
- `docs/roadmap.md`

Summarize the current state in 5 bullets. The user does not need to see this; you do.

## Phase 2: Determine change scope

The user request maps to one or more of these change types:
- **A** — adding a new feature to `features.md` (Planned section)
- **B** — reordering `roadmap.md`
- **C** — changing tech stack or architecture in `architecture.md`
- **D** — deprecating a shipped feature
- **E** — adding/removing a hard constraint

Identify which type(s). If unclear, ask the user **one** clarifying question.

## Phase 3: Clarifying questions (if needed)

If the request is ambiguous, ask up to 3 questions — but only if you genuinely cannot proceed without an answer. Skip if request is clear.

## Phase 4: Draft the change

Write the proposed change as a unified diff (in your head — don't apply yet). For each file you'd touch:
- File: `docs/<file>.md`
- Specific section: `## <section>`
- Before/after of the affected lines

## Phase 5: Critic review (gate-1 equivalent)

Invoke the senior-critic agent with:
- Inputs: the proposed diff, current Master Plan files, all `.claude/lessons/`
- Gate: 1 (treat plan changes like spec changes)
- Slug: `plan-improve-YYYY-MM-DD-HHMM`

The critic returns its summary line. Save the report.

If Critical findings exist, present them to the user and offer:
- `continue` — apply the change anyway (note in commit message)
- `address` — re-draft based on critic findings
- `override` — apply with written justification appended to the report

## Phase 6: Apply the change

Edit the affected `docs/*.md` files with the changes from Phase 4 (modified per critic if user chose `address`).

Verify the soft size budgets are not exceeded:
- `architecture.md` ≤ 300 lines
- `features.md` ≤ 500 lines
- `roadmap.md` ≤ 200 lines

If exceeded, warn the user and suggest splitting (don't auto-split).

## Phase 7: Commit

```bash
git add docs/architecture.md docs/features.md docs/roadmap.md
git commit -m "docs: plan-improve — <one-line summary of change>

Critic report: <path-to-report>"
```

## Phase 8: Report

Print:
```
✓ Master Plan updated.

Files changed:
  - docs/<file>.md (<+N -M> lines)
  ...

Critic gate-1: <N> Critical / <M> Important / <P> Nice-to-have
Report: docs/superpowers/critic-reports/<filename>

Next: /feature "<something from the updated plan>"
```

## Error handling

| Failure | Action |
|---|---|
| Master Plan not initialized | Stop, suggest `/init` |
| Critic returns Critical findings, user picks `address` | Re-run Phase 4 with critic findings as input; loop max 3 times |
| Size budget exceeded | Warn but apply; suggest manual split |
| Git not in a repo | Skip commit, warn user |
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands/plan-improve.md
test -f "$F" && echo EXISTS
grep -q "^description:" "$F" && echo "frontmatter OK"
for phase in "Pre-flight" "Phase 1" "Phase 5" "Phase 7" "Phase 8"; do
  grep -q "$phase" "$F" && echo "$phase present"
done
grep -q "senior-critic" "$F" && echo "critic invoked"
grep -q "git commit" "$F" && echo "commit step present"
```
Expected: all checks pass.

- [ ] **Step 4: Commit (skip)**

---

## Task 13: Write `.claude/commands/feature.md` — the orchestrator

**Files:**
- Create: `.claude/commands/feature.md`

This is the largest and most important file. It implements the full automatic pipeline (Phase 1-11 from the spec).

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.claude/commands/feature.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `.claude/commands/feature.md`:
```markdown
---
description: Build new functionality end-to-end. Full automatic pipeline (ground → brainstorm → critic → plan → TDD → critic → verify → finish). User intervenes only on real clarifying questions or Critical critic findings.
argument-hint: "<feature description>"
---

# /feature — build new functionality (full auto pipeline)

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

3. **Announce intent:**
   - Tell the user: "Starting /feature pipeline for: <description>. Slug: <SLUG>. I'll proceed automatically through 11 phases. I'll only stop for real clarifying questions or Critical critic findings."

---

## Phase 1: Ground

Read in full:
- `docs/architecture.md`
- `docs/features.md`
- `docs/roadmap.md`
- Every file under `.claude/lessons/`

Detect libraries from package manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, etc.). For each detected library that is *plausibly relevant* to this feature, query Context7:

```
mcp__plugin_context7-plugin_context7__resolve-library-id { libraryName: "<lib>" }
mcp__plugin_context7-plugin_context7__query-docs { id: "<resolved>", topic: "<topic relevant to feature>" }
```

Produce a 5-10 bullet **ground summary** (internal — not shown to user unless asked):
- Architecture context (where this feature fits)
- Existing features it interacts with
- Roadmap position
- Lessons that match this feature's domain (cite filenames)
- Library-specific gotchas from Context7
- Open questions for brainstorm

---

## Phase 2: Brainstorm

Invoke `superpowers:brainstorming` with:
- The user's feature description
- The ground summary as context

The brainstorming skill produces a spec. Save it to:
```
docs/superpowers/specs/<SLUG>.md
```

If the brainstorm has a real clarifying question (not stylistic), ask the user. Wait for answer. Otherwise proceed silently.

---

## Phase 3: Critic gate-1

Invoke the `senior-critic` subagent (defined in `.claude/agents/senior-critic.md`):

```
Use the senior-critic subagent to review this spec at gate 1.
Inputs:
  - Spec: docs/superpowers/specs/<SLUG>.md
  - docs/architecture.md, docs/features.md, docs/roadmap.md
  - All files under .claude/lessons/
  - Original user request: "<$ARGUMENTS>"
Slug: <SLUG>
Gate: 1
```

The critic saves a report and returns a one-line summary like:
`critic gate 1: 0 Critical / 2 Important / 1 Nice-to-have. Report: docs/superpowers/critic-reports/<SLUG>-gate1.md`

**Decision:**
- If Critical > 0: present summary to user, ask `continue / address / override`. Default to `address` if user does nothing within 1 message exchange.
  - `address` → re-run Phase 2 with critic findings as additional input. Max 2 retries; if still Critical, force user decision.
  - `override` → user must provide a written reason; append to the report file.
  - `continue` → proceed.
- If Critical == 0: proceed silently. Mention only the one-line summary.

---

## Phase 4: Plan

Invoke `superpowers:writing-plans` on the spec at `docs/superpowers/specs/<SLUG>.md`. Save the plan to:
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
EPIC_ID=$(bd create -t epic "<feature description>" | grep -oE 'bd-[0-9]+')
bd dep add <task-id> $EPIC_ID --type parent-child
```

Update `docs/features.md`: move/add the feature to "In progress" with the epic ID and slug.

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
- Test that should fail doesn't fail → stop (test is broken)
- Verification command fails → stop

---

## Phase 8: Critic gate-2

Invoke the `senior-critic` subagent at gate 2:

```
Use the senior-critic subagent to review at gate 2.
Inputs:
  - Diff: git diff main..HEAD (or git diff main..feature/<slug> if in worktree)
  - Spec: docs/superpowers/specs/<SLUG>.md
  - docs/architecture.md, docs/features.md
  - All files under .claude/lessons/
Slug: <SLUG>
Gate: 2
```

Critic saves report, returns one-line summary.

**Decision:**
- If Critical > 0: present to user, ask `continue / address / override`. Default `address`.
  - `address` → for each Critical/Important finding, run `bd create` to add a new task, then loop back to Phase 7 for those tasks. Max 2 cycles.
  - `override` → require written reason in report.
  - `continue` → proceed.
- If Critical == 0: proceed.

---

## Phase 9: Verify

Invoke `superpowers:verification-before-completion`. Identify and run the proving command(s) for this feature:
- Test suite: `<project's test command>`
- Lint: `<lint command if configured>`
- Type check: `<typecheck command if configured>`
- Build: `<build command if configured>`

For each: run fresh, read full output, capture exit code. If any fail → STOP, surface output, do not proceed.

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

Update `docs/features.md`: move the feature from "In progress" to "Shipped" with date:
```
- [x] [F-XXX] <slug> — <description> — shipped YYYY-MM-DD
```

```bash
git add docs/features.md
git commit -m "docs: feature shipped — <slug>"
```

Close the beads epic:
```bash
bd close $EPIC_ID --reason "Shipped — merge SHA <sha>"
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

Next: /feature "<next thing>" or git push (manual).
```

---

## Error handling summary

| Failure | Action |
|---|---|
| Master Plan unfilled | Stop, suggest `/init` |
| Brainstorm clarifying question | Surface to user, wait |
| Critic gate-1 Critical, user `address` | Re-run brainstorm with findings; max 2 retries |
| Critic gate-2 Critical, user `address` | Add tasks, re-loop TDD; max 2 cycles |
| TDD attempt loop > 3 | Stop, surface |
| Verify command non-zero | Stop, surface |
| Merge conflict | Stop, surface, do NOT auto-resolve |
| `gh` not installed when `pr` mode | Fall back to `merge` mode, warn user |

## Constraints

- This command should NEVER push to a remote.
- This command should NEVER skip critic gates silently.
- This command should NEVER claim done without Phase 9 verification passing.
- This command should NEVER update `docs/architecture.md` (only `/plan-improve` does that).
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands/feature.md
test -f "$F" && echo EXISTS
grep -q "^description:" "$F" && echo "frontmatter OK"
for phase in "Pre-flight" "Phase 1" "Phase 2" "Phase 3" "Phase 4" "Phase 5" "Phase 6" "Phase 7" "Phase 8" "Phase 9" "Phase 10" "Phase 11"; do
  grep -q "## $phase" "$F" && echo "$phase present"
done
grep -q "senior-critic" "$F" && echo "critic invoked"
grep -q "superpowers:brainstorming" "$F" && echo "brainstorm invoked"
grep -q "superpowers:writing-plans" "$F" && echo "writing-plans invoked"
grep -q "superpowers:test-driven-development" "$F" && echo "TDD invoked"
grep -q "superpowers:verification-before-completion" "$F" && echo "verify invoked"
grep -q "bd create" "$F" && echo "beads tasks"
grep -q "git commit" "$F" && echo "commits"
grep -q "Context7\|context7" "$F" && echo "context7 referenced"
```
Expected: `EXISTS` + frontmatter + 12 phase confirmations + 8 component confirmations.

- [ ] **Step 4: Commit (skip)**

---

## Task 14: Write `.claude/commands/improve.md`

**Files:**
- Create: `.claude/commands/improve.md`

This file is largely the same as `feature.md` but with a different ground emphasis and constraint ("modify existing only, don't add new features").

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.claude/commands/improve.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `.claude/commands/improve.md`:
```markdown
---
description: Modify existing behavior. Same auto pipeline as /feature, but ground phase emphasizes finding existing code paths to change. Strictly behavior change — does not add new features.
argument-hint: "<change to existing behavior>"
---

# /improve — modify existing behavior (full auto pipeline)

**Input:** `$ARGUMENTS` (description of the behavior change)

This command runs the **same 11-phase pipeline as `/feature`** with two differences:

1. **Phase 1 (ground)** emphasizes locating existing code paths to change (uses Grep + Read against current src/) and explicitly identifies the shipped feature(s) being modified by referencing `docs/features.md` Shipped section.

2. **Constraint:** This command MUST NOT add any new feature to `docs/features.md`. If during brainstorm or critic it becomes clear the work is actually new functionality, STOP and tell the user: "This work is a new feature, not an improvement. Run `/feature \"<description>\"` instead."

## Pre-flight

1. Master Plan must exist:
   - Run: `grep -q "UNFILLED" docs/architecture.md 2>/dev/null && echo unfilled || echo filled`
   - If `unfilled` → STOP. Print: "Run `/init \"<app description>\"` first."

2. At least one feature must be in `docs/features.md` Shipped section:
   - Run: `grep -A 100 "^## Shipped" docs/features.md | grep -q "^- \[x\]"`
   - If no shipped features → STOP. Print: "Nothing has shipped yet. Use `/feature` to build, not `/improve`."

3. Generate `$SLUG` as in `/feature`.

4. Announce: "Starting /improve pipeline for: <description>. Will modify existing behavior only — if work expands to new feature, will stop and redirect."

---

## Phase 1: Ground (improve-flavored)

In addition to the standard ground:
- Read `docs/features.md` Shipped section in full.
- Identify which shipped feature(s) this change targets. If unclear, ask the user one question.
- Run `Grep` for keywords from `$ARGUMENTS` across `src/` (or equivalent source dir) to locate the affected code paths.
- List the specific files that will be touched. If the list is empty, STOP and tell the user: "I can't locate existing code matching this description. Either the feature isn't shipped, or rephrase the request."

Then proceed with the standard ground steps (architecture.md, lessons, Context7).

---

## Phases 2-12: Same as `/feature.md`

All other phases run identically to `/feature`. Reference `.claude/commands/feature.md` for the full text — do not duplicate it here.

**Differences in specific phases:**

- **Phase 5 (Beads tasks):** Update `docs/features.md` should NOT add a new feature. Instead, append a note to the existing feature's line: `(behavior change in progress: <slug>)`.
- **Phase 8 (Critic gate-2):** The critic should be told this is an improvement; it pays special attention to "did this break the existing behavior the feature already shipped?" and "are there regression tests?"
- **Phase 11 (Master Plan update):** Do NOT move anything in `docs/features.md` (the feature was already Shipped). Just remove the `(behavior change in progress)` note. Optionally append a `- behavior changed YYYY-MM-DD: <slug>` sub-bullet under the feature.

---

## Branch naming

Use `improve/<slug>` instead of `feature/<slug>`.

## Commit prefixes

Use `refactor:` or `fix:` (not `feat:`) for commit messages during the TDD loop.

## Error handling

Same as `/feature`, plus:

| Failure | Action |
|---|---|
| Brainstorm reveals work is actually a new feature | STOP, tell user to run `/feature` instead |
| Cannot locate existing code matching description | STOP, ask user to rephrase or run `/feature` if it's actually new |
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands/improve.md
test -f "$F" && echo EXISTS
grep -q "^description:" "$F" && echo "frontmatter OK"
grep -q "MUST NOT add any new feature" "$F" && echo "constraint stated"
grep -q "improve/<slug>" "$F" && echo "branch naming"
grep -q "refactor:" "$F" && echo "commit prefix"
grep -q "Same as \`/feature.md\`" "$F" && echo "delegates to feature.md"
```
Expected: all checks pass.

- [ ] **Step 4: Commit (skip)**

---

## Task 15: Write `.claude/commands/fix.md`

**Files:**
- Create: `.claude/commands/fix.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.claude/commands/fix.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `.claude/commands/fix.md`:
```markdown
---
description: Debug a bug end-to-end. Uses systematic-debugging instead of brainstorming. Always ends by writing a lesson file to .claude/lessons/.
argument-hint: "<bug description>"
---

# /fix — debug + auto-lesson

**Input:** `$ARGUMENTS` (the bug description — symptom or repro)

## Pre-flight

1. Master Plan must exist (same check as `/feature`).
2. Generate `$SLUG` as in `/feature`, but prefix with `fix-`: `YYYY-MM-DD-fix-<slug>`.
3. Announce: "Starting /fix pipeline for: <description>. Will debug, fix, then write a lesson file."

---

## Phase 1: Ground (debug-flavored)

Read:
- `docs/architecture.md`
- `docs/features.md` (which feature does this bug touch?)
- `.claude/lessons/` — pay extra attention; this bug may already have a lesson that was ignored.

If a lesson's `trigger:` matches this bug, surface it immediately to the user: "Lesson `<filename>` warned about this. Either the lesson wasn't applied or its `prevention:` is incomplete. Updating it may be appropriate after the fix."

---

## Phase 2: Systematic debugging

Invoke `superpowers:systematic-debugging`:

1. Reproduce the bug (write a failing test that captures the symptom)
2. Hypothesis (what's the most likely cause?)
3. Single-variable test of the hypothesis
4. Root cause identified
5. STOP after 3 failed hypotheses → step back, question architecture

The output of this phase: a confirmed root cause + a failing test that proves the bug.

Save the diagnosis as a brief markdown to:
```
docs/superpowers/specs/<SLUG>-diagnosis.md
```

---

## Phase 3: Critic gate-1 (diagnosis review)

Invoke `senior-critic` at gate 1 with the diagnosis as the "spec".

Critic asks: is this really the root cause, or just a symptom of a deeper issue? Are there other places this same bug exists? Are there missing tests for similar conditions?

If Critical findings on the diagnosis: address (re-debug) before fixing.

---

## Phase 4: Plan + bd-tasks (small)

For most bugs, the plan is 1-3 tasks:
- Fix the root cause
- Verify the failing test now passes
- Add regression test(s) for related conditions surfaced by critic

Create beads tasks via `bd create`.

---

## Phase 5: TDD loop

For each task: RED already exists from Phase 2; jump to GREEN. Then REFACTOR. Commit with `fix(<slug>): <task title>`.

If the bug touches multiple files, the worktree decision applies same as `/feature` (>3 tasks → worktree).

---

## Phase 6: Critic gate-2

Same as `/feature` Phase 8.

---

## Phase 7: Verify

Same as `/feature` Phase 9. Plus: explicitly run the test from Phase 2 to prove the bug is fixed.

---

## Phase 8: Finish

Same as `/feature` Phase 10 (merge/PR per `pipeline.finish_mode`).

---

## Phase 9: Lesson write (replaces master-plan-update)

Construct a lesson file from the debug session. Use the schema in `docs-meta/LESSON_FORMAT.md`.

Filename:
```
.claude/lessons/<SLUG>.md
```
(where SLUG is `YYYY-MM-DD-fix-<slug>` — but for the lesson, drop the `fix-` prefix to make the trigger more general)

Content (fill from the debug session):

```markdown
---
trigger: <derive from the affected files / domain — what kind of work brings this back?>
symptom: <one line, from Phase 1 description>
root_cause: <from Phase 2>
prevention: <one imperative rule — what should the agent do next time to avoid this?>
---

<2-3 sentences of context. What you tried, what surprised you, what to remember.>
```

Then:
```bash
git add .claude/lessons/<filename>
git commit -m "lesson: <one-line trigger>"
```

If a lesson already existed that matched this bug's trigger (surfaced in Phase 1), append `## Update YYYY-MM-DD` section to that lesson with the new prevention rule, instead of creating a new lesson.

---

## Phase 10: Final report

```
✓ Bug fixed: <description>

Diagnosis:    docs/superpowers/specs/<SLUG>-diagnosis.md
Critic:       gate-1 (<summary>), gate-2 (<summary>)
Tasks:        <N> beads tasks closed
Lesson:       .claude/lessons/<filename>
Diff:         <merge-sha or PR URL>

Lesson trigger: <trigger>
Lesson prevention: <prevention rule>

Next: /feature "<next thing>" or git push (manual).
```

---

## Constraints

- This command MUST end with a lesson written. If you can't formulate a lesson, the root cause wasn't deep enough — go back to Phase 2.
- This command does NOT update `docs/features.md` (bug fixes don't change features).
- This command does NOT update `docs/architecture.md` (use `/plan-improve` if architecture needs to change in response).
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands/fix.md
test -f "$F" && echo EXISTS
grep -q "^description:" "$F" && echo "frontmatter OK"
grep -q "systematic-debugging" "$F" && echo "uses systematic-debugging"
grep -q "Lesson write" "$F" && echo "lesson phase present"
grep -q "MUST end with a lesson" "$F" && echo "lesson constraint stated"
grep -q "trigger:" "$F" && echo "lesson schema referenced"
```
Expected: all checks pass.

- [ ] **Step 4: Commit (skip)**

---

## Task 16: Write `.claude/commands/lesson.md`

**Files:**
- Create: `.claude/commands/lesson.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.claude/commands/lesson.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `.claude/commands/lesson.md`:
```markdown
---
description: Manually record a lesson learned. Used rarely (for things not coming out of /fix). Prompts for trigger / symptom / root_cause / prevention.
argument-hint: "[optional one-line context]"
---

# /lesson — manually record a lesson

**Input:** `$ARGUMENTS` (optional one-line context to seed the lesson)

Most lessons are written automatically by `/fix`. Use this command only when you want to capture something that wasn't a debugging session — e.g. a near-miss, a code review insight, a one-off realization from manual exploration.

## Phase 1: Prompt for fields

Ask the user **four questions in sequence** (one per message), referring to `docs-meta/LESSON_FORMAT.md` for guidance:

1. **trigger:** "When does this lesson apply? (one phrase the agent can match against future task descriptions or file paths)"
2. **symptom:** "What did you observe? (one line, past tense)"
3. **root_cause:** "What was the actual reason? (not the symptom — the underlying cause)"
4. **prevention:** "What's the imperative rule that prevents this? (start with a verb)"

Then:

5. **context:** "2-3 sentences of context for future-you to recognize the situation. Hard limit 5 sentences."

If `$ARGUMENTS` is provided, use it as a starting hint when asking the questions.

## Phase 2: Validate against schema

Check the answers against `docs-meta/LESSON_FORMAT.md`:
- `trigger` not too broad ("bugs", "code") and not too narrow (specific commit SHAs)
- `prevention` starts with a verb
- `root_cause` is a cause, not a symptom
- Body ≤ 5 sentences

If any fail, push back: "Your `trigger:` is too broad — fires on every task. Can you narrow it?"

## Phase 3: Generate filename

Format: `YYYY-MM-DD-<3-6-word-topic-slug>.md`

The slug should describe the **topic**, not the symptom. Derive from the `trigger` field.

## Phase 4: Write the file

Save to `.claude/lessons/<filename>`.

## Phase 5: Commit

```bash
git add .claude/lessons/<filename>
git commit -m "lesson: <one-line trigger>"
```

## Phase 6: Report

```
✓ Lesson recorded.

File:       .claude/lessons/<filename>
Trigger:    <trigger>
Prevention: <prevention>

Total lessons: <count>
```

## Error handling

| Failure | Action |
|---|---|
| User abandons mid-questions | Discard partial input; print: "Lesson not recorded." |
| Field validation fails | Re-ask the failing field with explanation |
| File would conflict with existing lesson on same date+slug | Add suffix: `-2`, `-3`, etc. |
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands/lesson.md
test -f "$F" && echo EXISTS
grep -q "^description:" "$F" && echo "frontmatter OK"
for field in trigger symptom root_cause prevention; do
  grep -q "$field" "$F" && echo "asks for $field"
done
grep -q "LESSON_FORMAT.md" "$F" && echo "references format doc"
grep -q "git commit" "$F" && echo "commits"
```
Expected: all checks pass.

- [ ] **Step 4: Commit (skip)**

---

## Task 17: Write top-level `README.md`

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/README.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `README.md`:
```markdown
# project_template

A copy-paste starter kit for AI-assisted development with Claude Code.

Provides a 6-command pipeline (`/init`, `/plan-improve`, `/feature`, `/improve`, `/fix`, `/lesson`) that drives the full feature lifecycle automatically: ground → brainstorm → critic → plan → TDD → critic → verify → finish.

## What you get

- **Per-project `CLAUDE.md`** with hard rules (TDD, verification, lessons, Context7, critic gates)
- **6 slash commands** under `.claude/commands/` — only 6 commands the user ever types
- **Senior-critic subagent** (`.claude/agents/senior-critic.md`) — runs automatically at two gates
- **Master Plan templates** (`docs/architecture.md`, `docs/features.md`, `docs/roadmap.md`) — split for context efficiency
- **Lessons system** (`.claude/lessons/`) — every `/fix` writes a lesson; critic enforces them
- **Hooks** (`.claude/settings.json`) — session-start prints lesson count + command list
- **Source-of-truth pipeline doc** (`docs-meta/PIPELINE.md`) — what each command and phase does
- **Lesson schema** (`docs-meta/LESSON_FORMAT.md`)

## Prerequisites (one-time, on your machine)

See `CLAUDE_CODE_SETUP.md` for the full install of:
- Claude Code CLI
- Superpowers plugin
- Beads plugin + CLI
- Template Bridge plugin
- Context7 MCP

## Starting a new project

```bash
# Copy the template (skip the historical reference docs)
mkdir ~/projects/my-new-app
cd ~/projects/my-new-app

cp -r ~/Documents/00_CODE/project_template/.claude .
cp -r ~/Documents/00_CODE/project_template/docs .
cp -r ~/Documents/00_CODE/project_template/docs-meta .
cp ~/Documents/00_CODE/project_template/CLAUDE.md .
cp ~/Documents/00_CODE/project_template/.gitignore .

# Remove the placeholder spec/plan files (they're for the template repo, not your project)
rm -f docs/superpowers/specs/2026-04-25-ai-pipeline-design.md
rm -f docs/superpowers/plans/2026-04-25-ai-pipeline-implementation.md

# Open Claude Code and bootstrap
claude
> /init "todo app with realtime sync"
```

## The 6 commands

| Command | When |
|---|---|
| `/init "<desc>"` | Once per project — bootstrap |
| `/plan-improve "<change>"` | Refine the Master Plan (no code) |
| `/feature "<desc>"` | New functionality — full automatic pipeline |
| `/improve "<change>"` | Modify existing behavior — full automatic pipeline |
| `/fix "<bug>"` | Debug + auto-record lesson |
| `/lesson` | Manually record a lesson (rare) |

That's it. You never type `/brainstorm`, `/plan`, `/build`, `/critic`, `/verify`, or `/finish` — those are internal phases of the 6 commands above.

## Files NOT to copy when starting a new project

These exist in the template for documentation/historical reasons. Do NOT copy them into your new project:

- `CLAUDE_CODE_SETUP.md` — install instructions for your machine, not for projects
- `CLAUDE_CODE_WORKFLOW_GUIDE_RU.md` — original Russian-language workflow notes
- `docs/superpowers/specs/2026-04-25-ai-pipeline-design.md` — the spec for this template itself
- `docs/superpowers/plans/2026-04-25-ai-pipeline-implementation.md` — the plan for building this template

## Documentation

- `docs-meta/PIPELINE.md` — full pipeline reference (start here)
- `docs-meta/LESSON_FORMAT.md` — lesson file schema
- `CLAUDE.md` — per-project rules (loaded automatically by Claude Code)
- `docs/superpowers/specs/2026-04-25-ai-pipeline-design.md` — design rationale for this template

## License

MIT (or your choice — update this section per project after `/init`).
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/project_template/README.md
test -f "$F" && echo EXISTS
grep -q "6-command pipeline" "$F" && echo "describes pipeline"
grep -q "Starting a new project" "$F" && echo "has start instructions"
grep -q "Files NOT to copy" "$F" && echo "lists exclusions"
```
Expected: all checks pass.

- [ ] **Step 4: Commit (skip)**

---

## Task 18: End-to-end verification (acceptance test)

**Files:**
- None created — this task verifies all prior tasks together.

The spec's Acceptance Criterion #1 says: copying the template + running `/init` should produce a populated Master Plan, git repo, beads init, no feature code.

We can't actually run `/init` in this verification (it's a Claude command, not a shell command), but we **can** verify:
1. All template files exist with correct structure
2. `cp -r` produces a clean copy
3. The Markdown command files have correct frontmatter that Claude Code will recognize

- [ ] **Step 1: Run structural verification across all artifacts**

```bash
PT=/Users/vladislav/Documents/00_CODE/project_template

echo "=== File presence ==="
for f in CLAUDE.md README.md .gitignore \
         .claude/settings.json \
         .claude/agents/senior-critic.md \
         .claude/commands/init.md \
         .claude/commands/plan-improve.md \
         .claude/commands/feature.md \
         .claude/commands/improve.md \
         .claude/commands/fix.md \
         .claude/commands/lesson.md \
         docs/architecture.md \
         docs/features.md \
         docs/roadmap.md \
         docs-meta/PIPELINE.md \
         docs-meta/LESSON_FORMAT.md; do
  if test -f "$PT/$f"; then
    echo "  ✓ $f"
  else
    echo "  ✗ MISSING: $f"
  fi
done

echo ""
echo "=== JSON validity ==="
python3 -c "import json; json.load(open('$PT/.claude/settings.json')); print('  ✓ settings.json valid')" 2>&1

echo ""
echo "=== Command frontmatter ==="
for cmd in init plan-improve feature improve fix lesson; do
  F="$PT/.claude/commands/$cmd.md"
  head -5 "$F" | grep -q "^description:" && echo "  ✓ $cmd: has description" || echo "  ✗ $cmd: missing description"
done

echo ""
echo "=== Agent frontmatter ==="
F="$PT/.claude/agents/senior-critic.md"
head -10 "$F" | grep -q "^name: senior-critic$" && echo "  ✓ senior-critic: name OK"
head -10 "$F" | grep -q "^description:" && echo "  ✓ senior-critic: description OK"
head -10 "$F" | grep -q "^tools:" && echo "  ✓ senior-critic: tools OK"
```

Expected: every line printed has a `✓`, no `✗`. JSON parses cleanly.

- [ ] **Step 2: Simulate copy-to-new-project**

```bash
DEST=/tmp/test-project-template-$$
mkdir -p "$DEST"
cd "$DEST"

PT=/Users/vladislav/Documents/00_CODE/project_template
cp -r "$PT/.claude" .
cp -r "$PT/docs" .
cp -r "$PT/docs-meta" .
cp "$PT/CLAUDE.md" .
cp "$PT/.gitignore" .

# Remove template-specific files
rm -f docs/superpowers/specs/2026-04-25-ai-pipeline-design.md
rm -f docs/superpowers/plans/2026-04-25-ai-pipeline-implementation.md

echo "=== Dest tree ==="
find . -type f | sort

echo ""
echo "=== Cleanup ==="
cd /tmp
rm -rf "$DEST"
echo "  ✓ cleaned up"
```

Expected: tree includes CLAUDE.md, .gitignore, all 6 commands, senior-critic agent, all 3 master-plan templates, both docs-meta files, and 4 .gitkeep markers.

- [ ] **Step 3: Run a smoke check on slash command discoverability**

This requires a Claude Code session. Manual step for the user to run after the implementation completes:

```bash
# In a fresh terminal, in a copy of the template:
cd /tmp/smoke-test-$$ 
mkdir -p .
cp -r /Users/vladislav/Documents/00_CODE/project_template/{.claude,docs,docs-meta,CLAUDE.md,.gitignore} .
claude
# Inside claude:
> /help
# Verify /init, /plan-improve, /feature, /improve, /fix, /lesson all appear in the slash command list
```

Expected (manual): all 6 commands appear in `/help` output.

- [ ] **Step 4: Final acceptance summary**

Print a summary of what was built:

```bash
PT=/Users/vladislav/Documents/00_CODE/project_template
echo "=== Pipeline implementation complete ==="
echo ""
echo "Template files:"
find "$PT" -type f \( -name "*.md" -o -name "*.json" -o -name ".gitignore" \) \
  | grep -v "CLAUDE_CODE_" \
  | grep -v "/specs/2026-04-25-ai-pipeline-design.md" \
  | grep -v "/plans/2026-04-25-ai-pipeline-implementation.md" \
  | sort
echo ""
echo "Commands: 6 (/init, /plan-improve, /feature, /improve, /fix, /lesson)"
echo "Agents:   1 (senior-critic)"
echo "Hooks:    SessionStart, PreCompact (in .claude/settings.json)"
echo "Master Plan files: 3 (architecture.md, features.md, roadmap.md)"
echo "Lessons:  0 (folder ready under .claude/lessons/)"
```

Expected: clean summary output, file list matches the planned structure.

- [ ] **Step 5: Commit (skip)**

The template directory itself is not under git. After this implementation, the user can optionally `git init` the template directory to version-control it.

---

## Self-review checklist (run by the implementing agent)

After completing all 18 tasks:

1. **Spec coverage:**
   - §3 Modes: covered by `/init` (Mode 1) + `/feature`/`/improve`/`/fix` (Mode 2) ✓
   - §4 6 commands: all 6 created (Tasks 11-16) ✓
   - §5 Master Plan split: 3 templates created (Tasks 5-7) ✓
   - §6 Lessons: format doc (Task 9), `/fix` writes them (Task 15), `/lesson` manual (Task 16) ✓
   - §7 Critic agent: Task 10 ✓
   - §8 Git automation: covered in command files (Tasks 11-15) ✓
   - §9 File layout: matches Task 1 + all subsequent ✓
   - §10 CLAUDE.md content: Task 4 ✓
   - §11 Hooks: Task 3 (settings.json) ✓
   - §12 Internal-phase implementation: Task 13 (the worked example for `/feature.md`) ✓
   - §13 Edge cases: encoded in each command file's "Error handling" section ✓
   - §14 Acceptance criteria: Task 18 verifies structurally ✓

2. **Placeholder scan:** every code block in this plan contains real, complete content. Verified.

3. **Type/name consistency:**
   - `senior-critic` agent name used in `feature.md`, `improve.md`, `fix.md`, `plan-improve.md` ✓
   - `pipeline.finish_mode` key used consistently across `settings.json`, `feature.md`, `improve.md`, `fix.md`, `PIPELINE.md` ✓
   - Slug format `YYYY-MM-DD-<slug>` used consistently ✓
   - Lesson schema fields (trigger/symptom/root_cause/prevention) consistent across `LESSON_FORMAT.md`, `senior-critic.md`, `fix.md`, `lesson.md` ✓

---

## Post-implementation handoff (for the user)

After all tasks complete, present:

```
✓ Implementation complete. Project template ready.

To start a new project:
  cp -r ~/Documents/00_CODE/project_template/{.claude,docs,docs-meta,CLAUDE.md,.gitignore} ~/projects/<new-app>/
  cd ~/projects/<new-app>
  rm -f docs/superpowers/specs/2026-04-25-ai-pipeline-design.md
  rm -f docs/superpowers/plans/2026-04-25-ai-pipeline-implementation.md
  claude
  > /init "<one-line app description>"

Optional: version-control the template itself:
  cd ~/Documents/00_CODE/project_template
  git init && git add -A && git commit -m "chore: initial pipeline template"
```
