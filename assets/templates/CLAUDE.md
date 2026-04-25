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
| `/remember "<fact>"` | Capture a project-specific fact to Serena memory (rare) |

**Never expose internal phases** (`/brainstorm`, `/plan`, `/build`, `/critic`, `/verify`, `/finish`) to the user as commands. They run automatically inside `/feature`, `/improve`, `/fix`.

## Hard rules

1. **No production code without a failing test first.** Write the test, watch it fail for the right reason, then write code.
2. **No "done" claim without running the proving command and reading its output.** Evidence before assertions.
3. **Before writing code in any phase:** read every file under `.claude/lessons/` and apply any lesson whose `trigger:` matches the current task description or the files in scope. Cite the lesson filename in the implementation when you apply it.
4. **Before using ANY library, framework, SDK, or CLI tool:** query Context7. Run `mcp__plugin_context7-plugin_context7__resolve-library-id` then `mcp__plugin_context7-plugin_context7__query-docs`. Do not write library code from memory.
5. **Critic runs automatically** at gate-1 (post-spec) and gate-2 (post-diff). Critical findings block continuation unless the user explicitly overrides with a written reason saved to the report.
6. **Every TDD GREEN cycle ends with a `git commit`.** Every `/fix` ends with a lesson written to `.claude/lessons/`.
7. **Before starting `/feature` or `/improve`:** list `.serena/memories/` and read any memory whose name matches the work's topic or affected files. Cite the memory name when applying its content.

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

## Memories (Serena)

Stored in `.serena/memories/` — one markdown file per topic. Holds **stable project knowledge** that doesn't fit:

- Beads (tasks)
- Lessons (bug prevention rules)
- Master Plan (architecture/features/roadmap)
- Context7 (external library docs)

**Examples** of memory-worthy facts:
- Project conventions: "we use snake_case for db cols, camelCase in TS"
- Design decisions with rationale: "Postgres over Mongo because X"
- Domain-specific facts: "users billed in EUR not USD"
- Module-specific quirks: "auth middleware bypasses /healthz"

**Written by:**
- senior-critic at gate-2 of `/feature` and `/improve` (auto-suggested; pipeline writes them)
- senior-critic at gate-1 of `/plan-improve` (same)
- `/remember "<fact>"` (manual, anytime)

**Read by:** every `/feature` and `/improve` ground phase.

**NOT written by `/fix`** — bugs go to `.claude/lessons/`, not Serena memory.

## Git

- Pipeline automates: `init`, `add`, `commit`, branch creation, `worktree`, local merge
- Pipeline does NOT automate: `git push` (always manual — user controls remote)

## Plugins (assumed installed)

- `superpowers` — TDD, brainstorming, debugging, verification, code-review, worktrees, finishing
- `beads` — persistent task tracking across sessions
- `template-bridge` — 413+ specialist agent templates on demand
- `context7-plugin` — live library docs

If any are missing, the orchestrator should warn but continue with degraded behavior.
