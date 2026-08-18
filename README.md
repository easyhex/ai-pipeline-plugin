# ai-pipeline

A Claude Code plugin that ships an 8-command AI development pipeline with frontier-round elicitation and an explicit spec playback sign-off gate, an automatic senior-engineer critic at two gates, a lessons-learned flywheel, Serena memory for stable project knowledge, and a Playwright MCP visual-verify gate — six context layers in total.

## What you get

After installing this plugin, you can bootstrap any new project with one command and drive every feature end-to-end with a tiny set of slash commands:

| Command | When |
|---|---|
| `/init "<desc>"` | Bootstrap (one-time per project) |
| `/plan-improve "<change>"` | Refine the Master Plan (no code) |
| `/feature "<desc>"` | New functionality — full automatic pipeline |
| `/improve "<change>"` | Modify existing behavior — full automatic pipeline |
| `/fix "<bug>"` | Debug + auto-record a lesson |
| `/lesson` | Manually record a lesson (rare) |
| `/remember "<fact>"` | Capture a project-specific fact to Serena memory (rare) |
| `/questionnaire "<topic>"` | Generate a fill-in requirements questionnaire for a client or domain expert |

You never type `/brainstorm`, `/plan`, `/build`, `/critic`, `/verify`, or `/finish` — those are internal phases of the 8 commands above.

## Install

```bash
claude plugin marketplace add easyhex/ai-pipeline-plugin
claude plugin install ai-pipeline@ai-pipeline-marketplace
```

That's it. The 8 commands and the `senior-critic` agent are now available globally in any project.

## Bootstrap a new project

```bash
mkdir my-new-app
cd my-new-app
claude
> /init "todo app with realtime sync"
```

`/init` will:
1. Auto-install any missing prerequisite plugins (with a one-line `[y/n]` preview)
2. Run a short frontier-round interview (stakes / primary user / stack / scenarios / quality ranking / a forced NFR round)
3. Write the per-project file tree (CLAUDE.md, docs/, docs-meta/, .claude/)
4. Fill the 3 Master Plan files (architecture, features, roadmap) and confirm every drafted line with you BEFORE the first commit — unconfirmed proposals stay tagged `(proposed — unconfirmed)`
5. Run `git init` and `bd init` (if `bd` is installed)
6. Make the first commit

After `/init` completes, you start building features:

```
> /feature "add user signup with magic link auth"
```

The pipeline interviews you first (frontier rounds of numbered questions with recommended answers — see `docs-meta/ELICITATION.md`), plays the spec back for your explicit sign-off, and then runs autonomously — plan, beads tasks, TDD loop with auto-commits, critic gate-2, verify, merge or PR — stopping only for Critical critic findings or failures.

## Pipeline highlights

- **Elicitation layer (v0.4.0)** — a single canonical interview technique (`docs-meta/ELICITATION.md`: frontier rounds, facts-vs-decisions, question-hygiene lint, forced NFR round, typed `[NEEDS CLARIFICATION]`/`TBC` debt), a spec playback gate requiring explicit approval before any code, provenance sections separating user decisions from machine assumptions, and `/questionnaire` for requirements held in someone else's head.
- **Visual verification gate (v0.3.0)** — for frontend projects, Phase 9 drives Playwright MCP across the URLs listed in the spec, captures screenshots + a11y snapshots, fails the pipeline on console errors or blank renders. Configurable via `pipeline.visual_verify` in `.claude/settings.json`.

## Prerequisites

The plugin depends on 4 other Claude Code plugins. `/init` auto-installs any that are missing (with consent):

- **superpowers** — TDD, brainstorming, debugging, verification, code review
- **beads** — persistent task tracking across sessions
- **context7-plugin** — live library documentation via MCP
- **template-bridge** — 413+ specialist agent templates

Plus one CLI tool that must be installed manually:

- **`bd`** (Beads CLI): `brew install beads` (macOS) or `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash`
- **`uv`** (Python tool manager): `brew install uv` (macOS) or `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **`serena-agent`** (Python tool, auto-installed by `/init` via `uv` if `uv` is present)

After `/init`, the Serena MCP server is registered globally:

```bash
claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
```

## Architecture

The pipeline has three layers:

1. **8 user-facing commands** (in `commands/`) — auto-loaded by Claude Code
2. **`senior-critic` subagent** (in `agents/`) — auto-loaded, invoked at two gates per feature
3. **Per-project templates** (in `assets/templates/`) — written into your project by `/init`

Per-project files written by `/init`:

- `CLAUDE.md` — pipeline rules and the 8-command surface
- `docs/architecture.md` — Master Plan: target architecture (≤300 lines)
- `docs/features.md` — Master Plan: feature inventory (≤500 lines)
- `docs/roadmap.md` — Master Plan: ordered priorities (≤200 lines)
- `docs-meta/PIPELINE.md` — pipeline reference doc
- `docs-meta/LESSON_FORMAT.md` — lesson schema (4 YAML fields + 3-sentence body)
- `docs-meta/ELICITATION.md` — the interview technique (frontier rounds, question hygiene, markers)
- `docs/requirements/` — questionnaires for external stakeholders (written by `/questionnaire`)
- `.claude/settings.json` — hooks + enabled plugins (including `ai-pipeline`)
- `.gitignore` — common ignores
- `.claude/lessons/` — populated over time by `/fix` and `/lesson`
- `.serena/memories/` — Serena memory layer (stable project knowledge: conventions + design decisions)

For the full design rationale, see `docs/DESIGN_NOTES.md`.

## Updating the plugin

```bash
claude plugin install ai-pipeline@ai-pipeline-marketplace
```

This re-pulls from the source. Existing projects continue to work — they have their own copy of the templates from `/init` time.

## Hard rules (per-project CLAUDE.md)

After `/init`, the per-project `CLAUDE.md` enforces:

1. No production code without a failing test first
2. No "done" claim without running the proving command
3. Lessons applied automatically before each phase
4. Context7 query before any library/framework usage
5. Critic at gate-1 (post-spec) and gate-2 (post-diff)
6. Every TDD GREEN cycle ends with `git commit`; every `/fix` ends with a lesson
7. Before starting `/feature` or `/improve`: list `.serena/memories/` and read any memory whose name matches the work's topic or affected files
8. Elicitation per `docs-meta/ELICITATION.md`: facts looked up, decisions asked as frontier rounds; explicit spec playback sign-off before any plan or code

## Contributing

See `CLAUDE.md` for plugin contributor rules. Templates in `assets/templates/` are user-facing — keep them consistent with the per-project `CLAUDE.md` they ship.

## License

MIT — see [LICENSE](LICENSE).
