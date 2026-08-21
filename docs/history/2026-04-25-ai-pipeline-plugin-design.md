# AI Pipeline Plugin — Design Spec

**Date:** 2026-04-25
**Owner:** vladislav (nemtsovkz@gmail.com)
**Status:** Draft for review
**Predecessor:** `2026-04-25-ai-pipeline-design.md` (the per-project pipeline this plugin packages)
**GitHub repo:** https://github.com/easyhex/ai-pipeline-plugin
**Dev workspace:** `~/Documents/00_CODE/ai-pipeline-plugin/`

---

## 1. Goal

Package the 6-command AI development pipeline (currently shipped as the copy-paste-ready `~/Documents/00_CODE/project_template/`) as a **native Claude Code plugin** so the user can install it once and bootstrap any new project with `/init "<description>"`.

After this work:
- One install: `claude plugin marketplace add github:easyhex/ai-pipeline-plugin && claude plugin install ai-pipeline@ai-pipeline-marketplace`
- Per-project bootstrap: `mkdir my-app && cd my-app && claude` then `/init "<desc>"`
- No `cp -r` required. No remembering paths. No drift between user's project and template.

## 2. Non-goals

- **Not** cross-agent (Cursor/Copilot/Windsurf). Claude Code only.
- **Not** a language-specific scaffolder (Lean `/init` — does NOT write `package.json`, `pyproject.toml`, etc.). Frameworks remain user-driven.
- **Not** auto-installing the `bd` CLI (Beads requires `brew install beads` or curl — too presumptuous to run from a plugin).
- **Not** rewriting the pipeline phases or commands. The 6 command files and the `senior-critic` agent are migrated as-is from the verified `project_template/` implementation.

## 3. Architecture

### 3.1 Plugin repo layout

```
ai-pipeline-plugin/                       # GitHub: easyhex/ai-pipeline-plugin
├── .claude-plugin/
│   ├── plugin.json                       # name, version, description, license
│   └── marketplace.json                  # marketplace registration
├── commands/                             # auto-loaded by Claude Code as slash commands
│   ├── init.md                           # REWRITTEN — see §5
│   ├── plan-improve.md                   # copied verbatim from project_template
│   ├── feature.md                        # copied verbatim
│   ├── improve.md                        # copied verbatim
│   ├── fix.md                            # copied verbatim
│   └── lesson.md                         # copied verbatim
├── agents/
│   └── senior-critic.md                  # copied verbatim
├── assets/
│   └── templates/                        # files /init writes into the user's cwd
│       ├── CLAUDE.md
│       ├── architecture.md
│       ├── features.md
│       ├── roadmap.md
│       ├── PIPELINE.md
│       ├── LESSON_FORMAT.md
│       ├── gitignore                     # rendered as ".gitignore" by /init
│       └── settings.json                 # rendered into ./.claude/settings.json
├── docs/
│   ├── WORKFLOW_GUIDE_RU.md              # migrated from project_template
│   ├── DESIGN_NOTES.md                   # links to the original spec for design rationale
│   └── PIPELINE_REFERENCE.md             # mirror of PIPELINE.md as plugin docs (optional reading)
├── CLAUDE.md                             # plugin's OWN dev rules (for plugin contributors)
├── README.md                             # English install + usage
├── README_RU.md                          # Russian translation
├── LICENSE                               # MIT
├── settings.example.json                 # OPTIONAL global ~/.claude/settings.json hooks block
└── .gitignore                            # for the plugin repo itself
```

### 3.2 Component responsibilities

| Component | Single responsibility |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest: name=`ai-pipeline`, version=`0.1.0`, description, MIT |
| `.claude-plugin/marketplace.json` | Marketplace entry: name=`ai-pipeline-marketplace`, points to this repo |
| `commands/*.md` | The 6 user-facing slash commands. Claude Code auto-discovers them. |
| `agents/senior-critic.md` | Critic subagent. Available globally once plugin enabled. |
| `assets/templates/*` | **Single source of truth** for per-project file templates. `/init` reads + writes them. |
| `docs/*` | Long-form documentation. Not read at runtime. |
| `CLAUDE.md` (plugin's own) | Rules for **contributing** to the plugin (different from the per-project `CLAUDE.md` template). |
| `README.md` / `README_RU.md` | Install + usage docs for end users. |
| `settings.example.json` | Optional hooks block for users who want global hooks (advanced). Per-project hooks are written by `/init` into `./.claude/settings.json`. |

### 3.3 Naming

| Field | Value |
|---|---|
| GitHub repo | `easyhex/ai-pipeline-plugin` |
| Marketplace name | `ai-pipeline-marketplace` |
| Plugin name (in `claude plugin install`) | `ai-pipeline` |
| Initial version | `0.1.0` (pre-release; breaking changes OK) |
| License | MIT |

## 4. Install flow

```
# user, one time
claude plugin marketplace add github:easyhex/ai-pipeline-plugin
claude plugin install ai-pipeline@ai-pipeline-marketplace

# now the 6 commands and senior-critic agent are auto-loaded GLOBALLY
# in any new project folder
mkdir my-new-app && cd my-new-app
claude
> /init "todo app with realtime sync"
```

**What happens after `claude plugin install ai-pipeline@...`:**

1. The plugin's `commands/` and `agents/` are auto-discovered by Claude Code.
2. The 6 commands appear in `/help`.
3. The `senior-critic` subagent is available to be invoked.
4. The plugin's `assets/templates/` are NOT loaded into context (they're consumed only by `/init`).

## 5. `/init` — REWRITTEN for plugin context

The current `/init` (in `project_template/.claude/commands/init.md`) assumes the templates are already in the cwd (because they were `cp -r`'d). The plugin version must **write the templates from `assets/templates/`** into the user's cwd, then proceed.

### Phases

```
Phase 0: Pre-flight
  - Refuse if cwd already contains source code (package.json, pyproject.toml, src/, etc.)
  - Refuse if CLAUDE.md already exists at cwd
  - On refuse: explain and stop

Phase 1: Prerequisite scan + auto-install (NEW)
  - Run `claude plugin list` to detect installed plugins
  - Compute MISSING set from {superpowers, beads-marketplace plugin, context7-plugin, template-bridge}
  - If MISSING is non-empty:
    - Print one-line preview: "About to install: <comma-separated names>. Proceed? [y/n]"
    - Wait for user input
    - On 'y': run `claude plugin install <name>` for each missing
    - On 'n': continue with warning ("pipeline will work in degraded mode")
  - Detect `bd` CLI: run `command -v bd`. If missing: print one-line "beads CLI not found. Install: brew install beads. Continuing without bd init."
  - No auto-brew, no auto-curl.

Phase 2: Clarify (3 questions, exactly)
  - Q1: tech stack (A: Next.js+TS+Postgres, B: Python, C: Go, D: Other)
  - Q2: primary user (A: end consumer, B: developer, C: internal team, D: other)
  - Q3: top quality constraint (A: speed-to-ship, B: security, C: performance, D: maintainability)

Phase 3: Write template files from assets/ (NEW)
  - Resolve plugin install location (Claude Code provides it via plugin context, or shell out to plugin path)
  - For each file in assets/templates/, copy to the corresponding cwd path:
      assets/templates/CLAUDE.md           → ./CLAUDE.md
      assets/templates/architecture.md     → ./docs/architecture.md
      assets/templates/features.md         → ./docs/features.md
      assets/templates/roadmap.md          → ./docs/roadmap.md
      assets/templates/PIPELINE.md         → ./docs-meta/PIPELINE.md
      assets/templates/LESSON_FORMAT.md    → ./docs-meta/LESSON_FORMAT.md
      assets/templates/gitignore           → ./.gitignore
      assets/templates/settings.json       → ./.claude/settings.json
  - mkdir -p ./.claude/lessons
  - mkdir -p ./docs/superpowers/{specs,plans,critic-reports}

Phase 4: Fill placeholders
  - Use the 3 answers + the description to:
    - Replace UNFILLED in architecture.md; populate sections 1-6
    - Populate features.md with 5-8 initial planned features (F-001..F-008)
    - Populate roadmap.md Now/Next/Later/NotDoing with rationale
  - Use Context7 IF available to verify any framework-specific advice

Phase 5: Initialize beads (conditional)
  - If `bd` CLI present: `bd init`
    On success: `bd create -t epic "Initial development of <app name>"`
  - On failure or absence: skip silently after Phase 1 warning

Phase 6: Initialize git
  - `git init`
  - `git add -A`
  - `git commit -m "chore: scaffold via /init"` (multi-line body explaining what was done)
  - On failure (e.g. existing repo): skip git init, still add+commit

Phase 7: Report + handoff
  - Print structured summary of what was written
  - "Next steps: /feature \"<first feature>\""
```

### Key invariants

- `/init` MUST work in a brand-new empty folder.
- `/init` MUST NOT touch files outside cwd.
- `/init` MUST NOT install Node modules, Python packages, or any application dependencies.
- `/init` writes templates **from the plugin install location**. If the plugin can't be located on disk, `/init` fails with a clear error pointing to reinstall.

## 6. Other commands

`/plan-improve`, `/feature`, `/improve`, `/fix`, `/lesson` are **copied verbatim** from `project_template/.claude/commands/`. They reference the `senior-critic` agent (also copied verbatim). They reference `docs/architecture.md`, `docs-meta/LESSON_FORMAT.md`, `.claude/lessons/` — paths that exist in the user's cwd because `/init` wrote them.

No changes required.

## 7. Per-project files written by `/init`

These are the templates in `assets/templates/`. They are **byte-for-byte identical** to the corresponding files currently in `project_template/`:

| Template file (in plugin) | Destination in user's cwd | Source in `project_template/` |
|---|---|---|
| `assets/templates/CLAUDE.md` | `./CLAUDE.md` | `project_template/CLAUDE.md` |
| `assets/templates/architecture.md` | `./docs/architecture.md` | `project_template/docs/architecture.md` |
| `assets/templates/features.md` | `./docs/features.md` | `project_template/docs/features.md` |
| `assets/templates/roadmap.md` | `./docs/roadmap.md` | `project_template/docs/roadmap.md` |
| `assets/templates/PIPELINE.md` | `./docs-meta/PIPELINE.md` | `project_template/docs-meta/PIPELINE.md` |
| `assets/templates/LESSON_FORMAT.md` | `./docs-meta/LESSON_FORMAT.md` | `project_template/docs-meta/LESSON_FORMAT.md` |
| `assets/templates/gitignore` | `./.gitignore` | `project_template/.gitignore` |
| `assets/templates/settings.json` | `./.claude/settings.json` | `project_template/.claude/settings.json` |

The per-project `settings.json` template's `enabledPlugins` block must list `ai-pipeline@ai-pipeline-marketplace` so the new project gets the pipeline auto-enabled.

## 8. Plugin manifest (`.claude-plugin/plugin.json`)

```json
{
  "name": "ai-pipeline",
  "version": "0.1.0",
  "description": "6-command AI development pipeline: /init, /plan-improve, /feature, /improve, /fix, /lesson. Auto-critic at two gates. Lessons-learned flywheel. Beads + Superpowers integration.",
  "author": "vladislav (easyhex)",
  "license": "MIT",
  "homepage": "https://github.com/easyhex/ai-pipeline-plugin",
  "repository": "https://github.com/easyhex/ai-pipeline-plugin"
}
```

(Final field set adjusted to whatever Claude Code's plugin schema supports — this is the intent.)

## 9. Marketplace manifest (`.claude-plugin/marketplace.json`)

```json
{
  "name": "ai-pipeline-marketplace",
  "source": {
    "source": "github",
    "repo": "easyhex/ai-pipeline-plugin"
  },
  "plugins": [
    { "name": "ai-pipeline", "path": "." }
  ]
}
```

## 10. Documentation

### 10.1 README.md (English)

Sections:
1. What this plugin is (one paragraph)
2. Install (3-line bash block)
3. Usage — the 6 commands table
4. Bootstrap a new project — `mkdir + cd + claude + /init`
5. Prerequisites (auto-installed by `/init`, but listed for transparency)
6. Architecture (link to `docs/PIPELINE_REFERENCE.md`)
7. Updating: `claude plugin install ai-pipeline@ai-pipeline-marketplace`
8. Contributing (link to `CLAUDE.md`)
9. License (MIT)

Length budget: ≤300 lines.

### 10.2 README_RU.md (Russian)

Mirror of README.md in Russian. Translation of the same 9 sections.

### 10.3 docs/WORKFLOW_GUIDE_RU.md

Migrated from `project_template/CLAUDE_CODE_WORKFLOW_GUIDE_RU.md`. Updated to reference the plugin install path instead of the manual setup steps.

### 10.4 docs/DESIGN_NOTES.md

Short doc (≤100 lines): explains the design philosophy, links to the original specs in `project_template/docs/superpowers/specs/` for the deep rationale.

### 10.5 CLAUDE.md (plugin contributors)

Rules for anyone working on the plugin:
- Templates in `assets/templates/` are user-facing — keep them consistent with the per-project CLAUDE.md they ship to users
- Don't change command behavior without bumping the version
- Test changes by running `/init` in `/tmp/test-<n>/` and verifying outputs
- Lesson schema is canonical — `assets/templates/LESSON_FORMAT.md` is the source of truth

## 11. Migration from `project_template/`

After the plugin is built, tested, and published:

| `project_template/` artifact | Fate |
|---|---|
| `.claude/commands/*.md` (6 files) | Migrated to plugin `commands/`. Originals can be deleted. |
| `.claude/agents/senior-critic.md` | Migrated to plugin `agents/`. Original can be deleted. |
| `.claude/settings.json` | Migrated to plugin `assets/templates/settings.json`. |
| `.claude/lessons/.gitkeep` | Plugin's `/init` creates `.claude/lessons/` directly via `mkdir -p`. Original gitkeep can be deleted. |
| `CLAUDE.md` (per-project rules) | Migrated to plugin `assets/templates/CLAUDE.md`. |
| `docs/architecture.md`, `features.md`, `roadmap.md` | Migrated to plugin `assets/templates/`. |
| `docs-meta/PIPELINE.md`, `LESSON_FORMAT.md` | Migrated to plugin `assets/templates/`. |
| `.gitignore` | Migrated to plugin `assets/templates/gitignore` (no leading dot — `/init` adds it). |
| `README.md` | Replaced by plugin `README.md`. |
| `CLAUDE_CODE_SETUP.md` | Replaced by plugin `README.md`. Original can be deleted. |
| `CLAUDE_CODE_WORKFLOW_GUIDE_RU.md` | Migrated to plugin `docs/WORKFLOW_GUIDE_RU.md`. |
| `docs/superpowers/specs/2026-04-25-ai-pipeline-design.md` | Stays in `project_template/`. Linked from plugin's `docs/DESIGN_NOTES.md`. |
| `docs/superpowers/specs/2026-04-25-ai-pipeline-plugin-design.md` (this doc) | Stays in `project_template/`. Linked from plugin's `docs/DESIGN_NOTES.md`. |
| `docs/superpowers/plans/2026-04-25-ai-pipeline-implementation.md` | Stays in `project_template/`. Historical. |

**`project_template/` directory is NOT deleted automatically.** After the user has tested the plugin in a real new project and confirmed it works end-to-end, they can `rm -rf` it manually.

## 12. Acceptance criteria

The plugin is correctly built when:

1. `claude plugin marketplace add github:easyhex/ai-pipeline-plugin` succeeds.
2. `claude plugin install ai-pipeline@ai-pipeline-marketplace` succeeds.
3. In a fresh terminal, `mkdir /tmp/test-app && cd /tmp/test-app && claude`, then typing `/help` shows all 6 commands (`/init`, `/plan-improve`, `/feature`, `/improve`, `/fix`, `/lesson`).
4. `/init "todo app"` in `/tmp/test-app`:
   - Auto-installs missing prereqs (or warns if user declined)
   - Asks 3 clarifying questions
   - Writes the full per-project file tree (CLAUDE.md, docs/, docs-meta/, .claude/settings.json, .gitignore)
   - Fills in the 3 Master Plan files with concrete content
   - Runs `bd init` (if bd present) and `git init` + first commit
   - Prints the "Next: /feature ..." handoff
5. After `/init`, the cwd's `.claude/settings.json` lists `ai-pipeline@ai-pipeline-marketplace` in `enabledPlugins`.
6. `/feature "add user signup"` in the bootstrapped project runs end-to-end (uses senior-critic at gate-1, creates beads tasks, runs TDD, commits, runs critic at gate-2, verifies, finishes, updates features.md).

## 13. Risks & open questions

| Risk | Mitigation |
|---|---|
| Plugin schema for `plugin.json` may differ from what we wrote in §8 | Verify against template-bridge plugin's actual `.claude-plugin/plugin.json` before publishing |
| Agents directory location: `agents/` vs `.claude/agents/` may not be auto-discovered by Claude Code | Verify against a working plugin (template-bridge or superpowers) before publishing; fallback path is whatever they use |
| `claude plugin install` from inside a Claude Code session may not be supported the way we assume | Fallback: print the install command for the user to run instead of executing it directly |
| Plugin install location resolution (for `/init` to read `assets/templates/`) may require a Claude Code-specific API | Investigate `${PLUGIN_DIR}` env var or similar; fallback to known path under `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` |
| Auto-detecting which prereq plugins are installed | `claude plugin list` may not be the correct CLI; verify exact command before encoding into `/init` |
| `bd` CLI not auto-installable | Documented; user runs `brew install beads`. Acceptable. |
| README_RU translation drift over time | Add reminder in plugin CLAUDE.md to update both READMEs together |

These map to actions in the implementation plan, not blockers for this spec.

## 14. Out of scope (explicit non-asks)

- Cross-agent compatibility (Cursor/Copilot/Windsurf)
- Auto-installing system-level tools (`bd`, `gh`, `node`, `python`)
- Language-specific scaffolding (`package.json`, etc.) — Lean choice locked
- A web UI for browsing the plugin's commands
- Telemetry/analytics
- Public skills marketplace beyond this single plugin
- Migration tools to convert old `project_template/`-based projects (they're already working as-is; no need)

## 15. Definition of done

- [ ] Repo `easyhex/ai-pipeline-plugin` exists on GitHub with all files from §3.1
- [ ] Plugin installs cleanly via `claude plugin install ai-pipeline@ai-pipeline-marketplace`
- [ ] All 6 commands appear in `/help` after install
- [ ] `/init` end-to-end tested in `/tmp/test-app/` per §12 criterion 4
- [ ] One real feature shipped via `/feature` per §12 criterion 6
- [ ] README in both English and Russian
- [ ] LICENSE = MIT
- [ ] Version 0.1.0 tagged in git (`git tag v0.1.0 && git push origin v0.1.0`)
- [ ] Old `project_template/` flagged for manual deletion (not deleted automatically)
