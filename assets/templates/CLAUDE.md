# Pipeline rules

This project uses a 12-command AI development pipeline.
Source of truth: `docs-meta/PIPELINE.md`. Interview technique: `docs-meta/ELICITATION.md`.

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
| `/questionnaire "<topic>"` | Generate a fill-in requirements questionnaire for a client/expert (knowledge in someone else's head) |
| `/release` | Cut a product release: semver + human CHANGELOG + requirements diff + local tag |
| `/resume` | Continue an interrupted pipeline run (position derived from artifacts) |
| `/validate` | Check shipped features against their success criteria with real outcome evidence |
| `/deprecate "<feature>"` | Deliberately retire/break a shipped feature — with a committed migration plan |

**Never expose internal phases** (`/brainstorm`, `/plan`, `/build`, `/critic`, `/verify`, `/finish`) to the user as commands. They run automatically inside `/feature`, `/improve`, `/fix`.

## Hard rules

1. **No production code without a failing test first.** Write the test, watch it fail for the right reason, then write code.
2. **No "done" claim without running the proving command and reading its output.** Evidence before assertions.
3. **Before writing code in any phase:** read every file under `.claude/lessons/` and apply any lesson whose `trigger:` matches the current task description or the files in scope. Cite the lesson filename in the implementation when you apply it.
4. **Before using ANY library, framework, SDK, or CLI tool:** query Context7. Run `mcp__plugin_context7-plugin_context7__resolve-library-id` then `mcp__plugin_context7-plugin_context7__query-docs`. Do not write library code from memory.
5. **Critic runs automatically** at gate-1 (post-spec) and gate-2 (post-diff). Critical findings block continuation unless the user explicitly overrides with a written reason saved to the report.
6. **Every TDD GREEN cycle ends with a `git commit`.** Every `/fix` ends with a lesson written to `.claude/lessons/`.
7. **Before starting `/feature` or `/improve`:** list `.serena/memories/` and read any memory whose name matches the work's topic or affected files. Cite the memory name when applying its content.
8. **Elicitation follows `docs-meta/ELICITATION.md`.** Facts are looked up, never asked; decisions go to the user as numbered frontier rounds with ➡️ recommended answers, and the pipeline waits. The spec playback gate (Phase 3.5) requires explicit user approval before any plan or code — the original request authorizes planning only. Ceremony weight: `.claude/settings.json` → `pipeline.default_weight` (light/standard/deep, written by `/init`) seeds the weight recommendation; the confirmed weight lives in the spec frontmatter.
9. **Artifact language:** prose in the conversation's language; IDs (`F-001`), statuses, filenames, and greppable markers (`[NEEDS CLARIFICATION]`, `TBC:`, `TBD:`) always English, never localized.
10. **Requirements are living files.** `docs/requirements/F-NNN-<slug>.md` per `docs-meta/REQUIREMENTS_FORMAT.md`: created at spec approval, amended by `/improve` (update-vs-new rubric), `mid:` uuids written once and never edited. Acceptance criteria follow EARS (`docs-meta/SPEC_FORMAT.md`) — mandatory at weight standard/deep. Every gate `override` appends a `docs/risks.md` row; `/feature` and `/improve` append a `docs/TRACEABILITY.md` row on ship.

## Master Plan files

The "Master Plan" is split across four files to keep each one within context budget:

- `docs/architecture.md` — target architecture (≤300 lines)
- `docs/features.md` — feature inventory + status (≤500 lines)
- `docs/roadmap.md` — ordered priorities (≤200 lines)
- `docs/risks.md` — accepted-risk register (rows appended by gate overrides; retired only via `/plan-improve`)

All four carry `doc_version` + a `## Change history` table — every apply bumps the version and appends a row. Update `features.md` automatically when a feature ships (final phase of `/feature` and `/improve`). Update `architecture.md` and `roadmap.md` only via `/plan-improve` — never silently.

## Lessons

- Stored in `.claude/lessons/` as one markdown file per lesson
- Schema: `docs-meta/LESSON_FORMAT.md`
- Critic agent reads them at every gate and explicitly cites which apply
- `/lesson distill` compiles them into `docs-meta/DISTILLED.md`; ground reads the rules first and only the undistilled tail raw (critic gates and `/fix` still read everything)
- Never auto-delete; user prunes manually — and distillation never hides a lesson (un-clustered ones are listed in DISTILLED.md)

## Memories (Serena)

Stored in `.serena/memories/` — one markdown file per topic. Holds **stable project knowledge** that doesn't fit:

- Beads (tasks)
- Lessons (bug prevention rules)
- Master Plan (architecture/features/roadmap/risks)
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

## Playwright MCP (visual-verify gate)

For frontend projects, Phase 9 of `/feature`, `/improve`, `/fix` runs a **visual sub-step** that drives a real browser via Playwright MCP, navigates to URLs the spec lists under `## URLs to verify`, captures screenshots and accessibility snapshots, and stops the pipeline on:

- HTTP 4xx/5xx
- console errors (when `pipeline.visual_verify.fail_on_console_error: true`)
- empty/blank screenshots
- missing Playwright MCP / dev server

**Frontend detection:** the gate runs when `package.json` declares a framework dependency (react/vue/svelte/next/…), or when a root `index.html` exists **alongside** `package.json`. A bare `index.html` in a compute-only repo (WASM demo, docs page) does not trigger the gate.

Settings live under `.claude/settings.json` → `pipeline.visual_verify`:

| Field | Default | Meaning |
|---|---|---|
| `mode` | `required` | `required` / `best_effort` / `skip` |
| `base_url` | `http://localhost:3000` | probed first; if not reachable, pipeline starts dev server |
| `dev_command` | `auto` | `auto` reads `package.json scripts.dev`; otherwise explicit shell command |
| `dev_port_timeout_sec` | `60` | max wait for dev server boot |
| `fail_on_console_error` | `true` | console errors fail the gate in `required` mode |

Evidence is stored at `docs/superpowers/visual-evidence/<slug>/`.

## Quant-verify gate (v0.6)

For compute project classes (and any project declaring NFR proving commands), Phase 9c of `/feature`, `/improve`, `/fix` runs the **quantitative gate**: every NFR proving command from the feature's `docs/requirements/` file executes fresh per seed, with **pass^k** acceptance for deterministic oracles and an **anti-overclaim rule** (verdict `verified` only when every declared oracle actually ran — else `partial`). Evidence lands in `docs/superpowers/quant-evidence/<slug>/` (`summary.md` + `run-manifest.md` with commit SHA, seeds, platform, dependency versions, input hashes). Oracle taxonomy and tolerance rules: `docs-meta/NUMERICS_TESTING.md`.

Settings live under `.claude/settings.json` → `pipeline.quant_verify`:

| Field | Default | Meaning |
|---|---|---|
| `mode` | `by_class` | `by_class` resolves: compute classes → `required`, others → `skip`; explicit `required`/`best_effort`/`skip` wins |
| `seeds` | `[0]` | seed set exported as `SEED` to every proving command; pass^k across all of them |
| `budgets` | `[]` | global {name, command, threshold} checks run alongside NFR commands |
| `property_test_command` / `benchmark_command` / `tolerance_report_command` | `""` | project-wide checks (empty = skip) |
| `mutation` / `mutation_command` / `mutation_threshold` | `advisory` / `""` / `80` | `off` / `advisory` (survivors → Important findings) / `required` (empty command → verdict `partial`); the command receives `MUTATION_THRESHOLD` and must exit nonzero when the score falls below it |
| `test_runner` | `""` | runner for `verify.method: Test` evidence ids (e.g. `pytest -k`); empty while Test evidence is declared → those requirements count unexecuted (`partial`) |

`pipeline.project_class` (written by `/init`) drives the `by_class` resolution and the visual-gate default (compute classes and `cli` skip visual).
