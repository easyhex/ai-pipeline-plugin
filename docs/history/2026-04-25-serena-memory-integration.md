# Serena Memory Integration — Design Spec (v0.2.0)

**Date:** 2026-04-25
**Owner:** vladislav (nemtsovkz@gmail.com)
**Status:** Draft for review
**Predecessor:** `2026-04-25-ai-pipeline-plugin-design.md` (the v0.1.0 plugin)
**Target version:** `0.2.0`
**Repo:** https://github.com/easyhex/ai-pipeline-plugin

---

## 1. Goal

Add a fifth context layer to the pipeline — **Serena memory** — for stable project knowledge that doesn't fit any existing layer (Beads, lessons, master plan, Context7). Memory is auto-captured by the senior-critic at gate-2 and writable on demand via a new `/remember` command. Reading happens automatically in the ground phase of `/feature` and `/improve`.

After this work:
- 7 user-facing commands (was 6): `/init`, `/plan-improve`, `/feature`, `/improve`, `/fix`, `/lesson`, **`/remember`**
- `/init` auto-installs Serena via `uv` (with consent)
- Memories live in `.serena/memories/` per project (Serena's default)
- Senior-critic adds a "Memories to capture (suggested)" section at gate-2; pipeline auto-writes them
- Plugin version bumps `0.1.0` → `0.2.0`

## 2. Non-goals

- **No Serena symbol-level tools** (`find_symbol`, `replace_symbol_body`, etc.) — memory only. Q1 of brainstorming locked this.
- **No auto-install of `uv`** — fall back to docs if `uv` is missing. Q2 locked this.
- **No memory-format schema** — Serena's free-form markdown is fine; one file per topic.
- **No new memory-specific layer in `/fix`** — bugs continue to go to `.claude/lessons/`, not Serena.
- **No migration tool** for existing v0.1.0 projects — memory is purely additive; old projects work fine without it.

## 3. The 5-layer context model

| Layer | Storage | Stores | Read by | Written by |
|---|---|---|---|---|
| **Beads** | `.beads/` (Dolt/SQLite) | tasks + dependencies | `bd ready` per turn | every command (creates tasks) |
| **Lessons** | `.claude/lessons/*.md` | bug prevention rules | every phase (lesson trigger match) | `/fix`, `/lesson` |
| **Master Plan** | `docs/{architecture,features,roadmap}.md` | what+how+priorities | ground phase | `/init`, `/plan-improve`, `/feature` (features.md only) |
| **Context7** | live MCP query | external library docs | ground phase | n/a (read-only external) |
| **Serena memory** (NEW) | `.serena/memories/*.md` | conventions + design decisions | `/feature`, `/improve` ground | senior-critic at gate-2, `/remember` |

The layers do NOT overlap by design:
- Bug? → lesson
- Task? → bead
- Architectural decision? → master plan (architecture.md)
- External library quirk? → Context7 (or, if it's PROJECT-specific use of that library, → Serena memory)
- Project convention or ambient knowledge? → Serena memory

## 4. The new 7th command: `/remember`

**File:** `commands/remember.md` (in plugin)

### Frontmatter

```yaml
---
description: Capture a project-specific fact to Serena memory. Used for stable knowledge (conventions, design decisions, domain facts) that doesn't fit lessons or master plan. Plain wrapper around Serena's write_memory MCP tool.
argument-hint: "<one-line fact to remember>"
---
```

### Behavior

```
Phase 0: pre-flight
  - Verify Serena MCP server is reachable (mcp__serena__list_memories ping)
  - If not: print "Serena MCP not running. Start it: serena mcp start (or restart Claude Code)"
    and exit

Phase 1: derive a topic slug
  - From $ARGUMENTS, generate a 2-4 word kebab-case slug
  - Confirm with the user if ambiguous

Phase 2: write the memory
  - Call mcp__serena__write_memory with:
      name: <slug>
      content: $ARGUMENTS
  - If a memory with that slug already exists, append "## Update YYYY-MM-DD: $ARGUMENTS" to it

Phase 3: confirm
  - Print "✓ Wrote memory: <slug>"
  - Print the file path: .serena/memories/<slug>.md
```

No critic, no plan, no tests — `/remember` is a 1-second utility.

## 5. `/init` Phase 1 changes — auto-install Serena via `uv` (VERIFIED commands)

The current Phase 1 (auto-install plugin prereqs) gets a Serena addition. Verified commands from Serena's official docs at `oraios/serena/docs/02-usage/030_clients.md`:

```
# Install Serena (Python tool via uv)
uv tool install -p 3.13 serena-agent@latest --prerelease=allow

# Initialize project's .serena/ directory
serena init

# Register Serena as a USER-SCOPED MCP server (recommended by Serena docs)
claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
```

**Verified facts:**
- The MCP launch command is `serena start-mcp-server` (NOT `serena-mcp-server` — that earlier guess was wrong)
- Required flags: `--context claude-code --project-from-cwd`
- Recommended scope: `--scope user` (so Serena is available in any project; `--project-from-cwd` auto-targets the current cwd's `.serena/`)
- `claude mcp add --scope user` writes to `~/.claude.json` (`mcpServers` key)
- `claude mcp add` (default scope = local) writes to project-local config
- A convenience all-in-one `serena setup claude-code` exists but is less inspectable; we use the explicit commands

Pseudocode:

```
# Existing plugin auto-install (unchanged)
[detect missing of {superpowers, beads, context7-plugin, template-bridge}]
[consent prompt for plugin installs]
[auto-install or skip]

# NEW: detect uv + Serena
if command -v uv:
  serena_installed=false
  if uv tool list 2>/dev/null | grep -q "^serena-agent"; then
    serena_installed=true
  fi
  serena_mcp_registered=false
  if claude mcp list 2>/dev/null | grep -q "^serena:"; then
    serena_mcp_registered=true
  fi

  if not serena_installed OR not serena_mcp_registered:
    add "serena-agent (Python tool via uv) + MCP registration" to the consent prompt

    on consent:
      if not serena_installed:
        uv tool install -p 3.13 serena-agent@latest --prerelease=allow
      serena init                          # initializes .serena/ in cwd (idempotent)
      if not serena_mcp_registered:
        claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
      [if any step fails: warn, continue]
else:
  print: "uv not installed. Install: brew install uv (or curl -LsSf https://astral.sh/uv/install.sh | sh). Then re-run: serena init && claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd"
  print: "Continuing without Serena — /remember and memory-aware ground phases will be disabled."
```

The consent prompt becomes:
```
About to install missing prerequisites:
  - <missing-plugins>
  - serena-agent (Python tool via uv) + MCP registration  [if uv present and Serena missing]
Proceed? [y/n]
```

After installation:
- `serena init` creates `.serena/` (and `.serena/memories/`) in cwd; idempotent if rerun
- `claude mcp add --scope user serena ...` adds the MCP server entry to `~/.claude.json`'s `mcpServers` block
- Subsequent Claude Code sessions in any project will spawn the Serena MCP server, which uses `--project-from-cwd` to operate on whichever project's `.serena/` directory is current

## 6. Pipeline changes — read memories in ground; auto-write at gate-2

### `/feature` and `/improve` Phase 1 (Ground)

Add a step:

```
- mcp__serena__list_memories → returns list of memory names
- For each name whose slug substring-matches the feature description or affected files:
    mcp__serena__read_memory({ name: <name> }) → load into context
- Add a 3-bullet "Memory grounding" section to the internal ground summary
```

If Serena MCP not reachable, skip silently with a one-line note.

### `/feature` and `/improve` Phase 8 (Critic gate-2) — auto-write

After the senior-critic returns its report, the pipeline parses the new "Memories to capture (suggested)" section. For each suggestion:

```
mcp__serena__write_memory({
  name: <slug>,
  content: <one-line summary> + "\n\nCaptured by senior-critic at gate-2 of /feature \"<orig user request>\" on YYYY-MM-DD"
})
```

If a memory with that slug exists, append `## Update YYYY-MM-DD: ...` instead of overwriting.

### `/plan-improve` Phase 5 (Critic) — same auto-write logic

`/plan-improve` already invokes the critic. Same parse + auto-write applies.

### `/fix` — UNCHANGED

`/fix` continues to write lessons, not memories. Bugs are not memories.

## 7. Senior-critic agent updates

**File:** `agents/senior-critic.md` (modify)

Add to the output template:

```markdown
## Memories to capture (suggested)
- `<slug>`: <one-line summary> — <why it's stable knowledge worth remembering>
- ...

(If none: "None.")
```

Add to the agent's behavior section:

```
## Memory suggestions

After listing your findings, decide if any non-obvious knowledge surfaced
during this work would help future agents. Suggest a memory if:

- A non-obvious design choice with rationale (e.g. "auth uses session cookies
  not JWT because the backend is server-rendered")
- A project convention not enforced by tooling (e.g. "we always handle
  pagination in the controller, never the model")
- A domain-specific fact (e.g. "users are billed in EUR")

Do NOT suggest a memory for:
- Bugs (those are lessons)
- Tasks (those are beads)
- External library docs (those are Context7)
- Anything already in docs/architecture.md or docs/features.md

Slug rules: 2-4 kebab-case words derived from the topic.
Aim for 0-2 memory suggestions per gate. Quality over quantity.
```

## 8. Per-project `CLAUDE.md` template (in plugin's `assets/templates/CLAUDE.md`) — updates

Add Hard Rule #7:

```markdown
7. Before starting `/feature` or `/improve`: list `.serena/memories/`
   and read any memory whose name matches the work's topic or affected files.
```

Add a new section after Lessons:

```markdown
## Memories (Serena)

Stored in `.serena/memories/` (one markdown file per topic). Holds **stable
project knowledge** that doesn't fit Beads (tasks), lessons (bug prevention),
master plan (architecture/features), or Context7 (external libs).

Examples:
- Project conventions ("we use snake_case for db cols, camelCase in TS")
- Design decisions with rationale ("Postgres over Mongo because X")
- Domain-specific facts ("users billed in EUR not USD")
- Module-specific quirks ("auth middleware bypasses /healthz")

Written by:
- senior-critic at gate-2 (auto-suggested, pipeline writes them)
- `/remember "<fact>"` (manual, anytime)

Read by:
- every `/feature` and `/improve` ground phase

Not written by `/fix` (those produce lessons, not memories).
```

Update the user-facing commands table to add the 7th row:

```markdown
| `/remember "<fact>"` | Capture a project-specific fact to Serena memory (rare) |
```

## 9. `docs-meta/PIPELINE.md` template (in plugin's `assets/templates/PIPELINE.md`) — updates

Add a new section:

```markdown
## Context layers

The pipeline reads from 5 context layers:

| Layer | Stores | Read in | Written in |
|---|---|---|---|
| Beads | tasks + deps | every `bd ready` | every command |
| Lessons | bug prevention | every phase (trigger match) | `/fix`, `/lesson` |
| Master Plan | architecture, features, roadmap | ground phase | `/init`, `/plan-improve`, `/feature` (features.md only) |
| Context7 | external library docs | ground phase | n/a (read-only) |
| Serena memory | conventions + design decisions | `/feature`/`/improve` ground | senior-critic gate-2, `/remember` |
```

Update internal-phases table to add memory steps to ground (Phase 1) and gate-2 (Phase 8).

## 10. Per-project `settings.json` template — Serena MCP entry (VERIFIED location)

Add to `enabledPlugins` block: nothing (Serena is MCP, not a plugin).

The Serena MCP server entry is **user-scoped**, not project-scoped — it lives in `~/.claude.json` under the `mcpServers` key, registered by:

```
claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
```

Resulting `~/.claude.json` entry shape (verified format from existing entries like `sequential-thinking` and `playwright`):

```json
"mcpServers": {
  "serena": {
    "type": "stdio",
    "command": "serena",
    "args": ["start-mcp-server", "--context", "claude-code", "--project-from-cwd"],
    "env": {}
  }
}
```

The per-project `.claude/settings.json` does NOT need any Serena entry — `--project-from-cwd` auto-targets whichever project Claude Code is running in. The pipeline does NOT modify the per-project `settings.json` template for Serena; PIPELINE.md is updated to document the requirement.

## 11. README updates (EN + RU)

### `README.md` (English)

- Update the commands table from 6 → 7 rows (add `/remember`)
- Update Prerequisites section:
  - Add `uv` (Python package manager) — `brew install uv`
  - Add `serena-agent` — auto-installed by `/init` via `uv tool install`
- Update "What you get" section to mention Serena memory layer
- Update version reference if any

### `README_RU.md`

Mirror all changes in Russian.

## 12. Plugin contributor `CLAUDE.md` (top-level) — updates

Add to the "Hard rules for plugin changes":
> Serena memory is the 5th context layer. Any change to `commands/feature.md`, `commands/improve.md`, or `agents/senior-critic.md` must keep memory read/write logic intact.

Update version policy: bump from 0.1.0 → 0.2.0 for this change (new command + new auto-install + new critic behavior = MINOR bump per semver pre-1.0).

## 13. `docs/DESIGN_NOTES.md` — link this spec

Add one bullet:
- "Serena memory integration (v0.2.0) — see this spec at `project_template/docs/superpowers/specs/2026-04-25-serena-memory-integration.md`"

## 14. Version bump

Files to update:
- `.claude-plugin/plugin.json`: `"version": "0.1.0"` → `"0.2.0"`
- `.claude-plugin/marketplace.json`: `plugins[0].version`: `"0.1.0"` → `"0.2.0"`
- Commit message: `feat: add Serena memory integration (v0.2.0)`
- Tag: `git tag v0.2.0 && git push origin v0.2.0`

## 15. Acceptance criteria

The integration is correctly built when:

1. `claude plugin install ai-pipeline@ai-pipeline-marketplace` (after publish) gets v0.2.0.
2. `/help` in a fresh project shows 7 commands including `/remember`.
3. `/init "todo app"` in `/tmp/test-app/`:
   - Detects `uv` (we know it's installed locally)
   - Adds `serena-agent` to consent prompt
   - On consent, runs `uv tool install` and `serena init` and `claude mcp add serena ...`
   - Reports successful Serena setup in the bootstrap summary
4. After `/init`, `.serena/memories/` exists (created by `serena init`).
5. `/remember "test app uses snake_case for db cols"` writes `.serena/memories/<slug>.md` and prints success.
6. `/feature "add user signup"`:
   - Phase 1 ground includes a "Memory grounding: <N> memories loaded" line in the internal summary
   - Phase 8 critic report includes a "Memories to capture (suggested)" section
   - If suggestions exist, files are written under `.serena/memories/`

## 16. Risks & open questions

| Risk | Mitigation / status |
|---|---|
| ~~`claude mcp add` exact syntax for Serena unknown~~ | **RESOLVED**: `claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd` (verified from Serena's `030_clients.md`) |
| ~~Serena MCP launch command name~~ | **RESOLVED**: `serena start-mcp-server` (verified — earlier `serena-mcp-server` guess was wrong) |
| `serena init` may prompt interactively | Plan task will run `serena init </dev/null` first as a probe; if it produces a TTY-required error, fall back to documenting the manual one-time setup |
| Critic may suggest too many memories (noise) | Critic prompt says "0-2 per gate, quality over quantity"; can be tuned by editing `senior-critic.md` later |
| User declines auto-install but pipeline tries to call `mcp__serena__*` later | All Serena MCP calls wrapped in try/skip; never block the pipeline |
| Existing v0.1.0 projects won't have Serena | Acceptable — memory is additive; old projects work fine without it. Document `serena init` + `claude mcp add` for retrofit |
| `--scope user` makes Serena spawn in EVERY Claude session, not just pipeline projects | Acceptable — `--project-from-cwd` makes Serena harmless in non-pipeline projects (it only operates on cwd's `.serena/` if it exists). User can `claude mcp remove serena` to disable globally if undesired |

## 17. Out of scope (explicit non-asks)

- Symbol-level Serena tools (find_symbol, replace_symbol_body)
- Migration tool for v0.1.0 projects
- Memory format schema (free-form markdown only)
- Auto-install of `uv` (curl install scripts)
- Memory pruning / consolidation tooling
- Cross-project memory sharing
- Memory search beyond list+read

## 18. Definition of done

- [ ] `commands/remember.md` exists and uses `mcp__serena__write_memory`
- [ ] `commands/init.md` updated to detect+install Serena via uv (with consent fallback)
- [ ] `commands/feature.md` updated with memory read in Phase 1 + auto-write in Phase 8
- [ ] `commands/improve.md` updated with same memory logic
- [ ] `commands/plan-improve.md` updated to auto-write memories from critic Phase 5
- [ ] `agents/senior-critic.md` updated with memory suggestion behavior
- [ ] `assets/templates/CLAUDE.md` updated with Hard Rule #7 and Memories section
- [ ] `assets/templates/PIPELINE.md` updated with 5-layer context table
- [ ] `README.md` and `README_RU.md` updated for 7 commands and Serena prereq
- [ ] `CLAUDE.md` (contributor) updated with new rule
- [ ] `docs/DESIGN_NOTES.md` updated to link this spec
- [ ] `plugin.json` and `marketplace.json` bumped to 0.2.0
- [ ] All changes committed
- [ ] Local install + smoke test of `/remember` and one `/feature` cycle
- [ ] Push to GitHub + tag v0.2.0
- [ ] Verify `claude plugin install ai-pipeline@ai-pipeline-marketplace` pulls v0.2.0
