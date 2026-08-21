# Serena Memory Integration — Implementation Plan (v0.2.0)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Serena memory as a 5th context layer to the existing `ai-pipeline` Claude Code plugin: a new `/remember` command, automatic memory capture by the senior-critic at gate-2, automatic memory loading in ground phases of `/feature` and `/improve`, and Serena auto-install via `uv` in `/init`. Ship as plugin version 0.2.0.

**Architecture:** Edit existing files in `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/` to add Serena MCP integration without breaking v0.1.0 behavior. New 7th command `/remember` is a thin wrapper around `mcp__serena__write_memory`. Existing commands gain memory hooks at specific phases. Senior-critic agent gains a "Memories to capture" output section. Templates (`assets/templates/CLAUDE.md`, `assets/templates/PIPELINE.md`) and READMEs are updated to document the 5th layer.

**Tech Stack:** Markdown command files, JSON manifests, Serena MCP tools (`mcp__serena__write_memory`, `read_memory`, `list_memories`), `uv tool install`, `claude mcp add --scope user`. No programming-language code.

**Reference spec:** `/Users/vladislav/Documents/00_CODE/project_template/docs/superpowers/specs/2026-04-25-serena-memory-integration.md`

**Working directory:** `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/` (existing git repo, already published as v0.1.0).

**Verified facts (from spec §5, §10, and live verification):**
- Install: `uv tool install -p 3.13 serena-agent@latest --prerelease=allow`
- Init project: `serena init`
- Register MCP (user-scoped): `claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd`
- MCP config lives in `~/.claude.json` under `mcpServers` key
- `uv` is installed locally at `/Users/vladislav/.local/bin/uv` (v0.9.15)
- Serena is NOT yet installed locally
- Serena MCP tool names follow the pattern `mcp__serena__<tool>` (write_memory, read_memory, list_memories)

---

## File structure to be produced

```
ai-pipeline-plugin/
├── .claude-plugin/
│   ├── plugin.json                       # MODIFY (Task 13): version 0.2.0
│   └── marketplace.json                  # MODIFY (Task 13): version 0.2.0
├── commands/
│   ├── init.md                           # MODIFY (Task 3): add Serena to Phase 1
│   ├── plan-improve.md                   # MODIFY (Task 7): auto-write memories from critic
│   ├── feature.md                        # MODIFY (Task 5): memory read in Phase 1, write in Phase 8
│   ├── improve.md                        # MODIFY (Task 6): same memory hooks as feature
│   ├── fix.md                            # NO CHANGE
│   ├── lesson.md                         # NO CHANGE
│   └── remember.md                       # NEW (Task 2)
├── agents/
│   └── senior-critic.md                  # MODIFY (Task 4): memory suggestion behavior
├── assets/templates/
│   ├── CLAUDE.md                         # MODIFY (Task 8): Hard Rule #7 + Memories section + 7-command table
│   ├── PIPELINE.md                       # MODIFY (Task 9): 5-layer context table
│   ├── (other templates unchanged)
├── docs/
│   └── DESIGN_NOTES.md                   # MODIFY (Task 12): link to Serena spec
├── README.md                             # MODIFY (Task 10): 7 commands + Serena prereq
├── README_RU.md                          # MODIFY (Task 11): mirror
├── CLAUDE.md                             # MODIFY (Task 12): contributor rule
└── (other files unchanged)
```

---

## Verification approach

This is configuration + prompt-file work, not code. "Tests" mean: file exists, JSON parses, frontmatter present, expected sections present, key strings present.

End-to-end test: Task 14 reinstalls the local plugin and smoke-tests `/remember` + a single `/feature` cycle in `/tmp/test-app/`.

---

## Task 1: Probe `serena init` interactivity

**Files:** none modified — this task only verifies behavior to inform Task 3.

The spec §16 flagged uncertainty about whether `serena init` prompts interactively. We probe before encoding behavior in `/init.md`.

- [ ] **Step 1: Install Serena locally (one-time, needed to probe)**

```bash
uv tool install -p 3.13 serena-agent@latest --prerelease=allow 2>&1 | tail -5
```
Expected: success message. If failure, STOP — investigate before continuing.

- [ ] **Step 2: Probe `serena init` with no TTY**

```bash
PROBE_DIR=/tmp/serena-probe-$$
mkdir -p "$PROBE_DIR"
cd "$PROBE_DIR"
serena init </dev/null 2>&1 | head -20
echo "exit: $?"
ls -la .serena/ 2>&1 | head -5
```

Capture the full output. **Decision rules:**
- If exit code is 0 and `.serena/` is created → `serena init` works non-interactively. **Encode in Task 3 as a plain command.**
- If exit code is non-zero with a "TTY required" or similar error → encode in Task 3 with the manual-fallback warning.
- If the command hangs (waits for input) → kill it, encode the manual-fallback warning, and document in Task 3.

- [ ] **Step 3: Probe `claude mcp add --scope user serena ...`**

Test the MCP add command with a fake binary first to avoid polluting state:

```bash
# Just test the syntax is valid (use --help to verify the command parses)
claude mcp add --scope user --help 2>&1 | grep -i "scope\|stdio" | head -5
```

If `--scope user` flag is documented (we already verified above it accepts `user|local|project`), we're good.

- [ ] **Step 4: Cleanup**

```bash
rm -rf /tmp/serena-probe-*
```

(Do NOT uninstall Serena — Task 14 needs it for smoke-testing.)

- [ ] **Step 5: Record findings**

Write a one-paragraph note for Task 3:
- "serena init: behavior on no-TTY input → <result>"
- "claude mcp add: --scope user accepted → yes"

This task has no commit — it's a probe.

---

## Task 2: Create `commands/remember.md` (the new 7th command)

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/remember.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/remember.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `commands/remember.md`:

````markdown
---
description: Capture a project-specific fact to Serena memory. Used for stable knowledge (conventions, design decisions, domain facts) that doesn't fit lessons or master plan. Plain wrapper around Serena's write_memory MCP tool.
argument-hint: "<one-line fact to remember>"
---

# /remember — capture a fact to Serena memory

**Input:** `$ARGUMENTS` (the one-line fact to remember)

This is a 1-second utility. No critic, no plan, no tests.

---

## Phase 0: Pre-flight

Verify the Serena MCP server is reachable. Try a no-op call to `mcp__serena__list_memories`:

If the call fails with "MCP server not found" or similar, STOP. Print:

```
Serena MCP server is not running.
To enable /remember, the Serena MCP server must be registered:
  uv tool install -p 3.13 serena-agent@latest --prerelease=allow   # if not installed
  serena init                                                       # in this project
  claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd

Then restart Claude Code.
```

If the call succeeds, proceed.

---

## Phase 1: Derive a topic slug

From `$ARGUMENTS`, generate a 2-4 word kebab-case slug describing the topic (not the symptom). Examples:

- `$ARGUMENTS` = "auth uses JWT 1h TTL, refresh 30d, rotate on each use" → slug `auth-jwt-ttl-rotation`
- `$ARGUMENTS` = "we bill all users in EUR not USD" → slug `billing-currency-eur`
- `$ARGUMENTS` = "frontend uses snake_case in db cols, camelCase in TS" → slug `naming-snake-vs-camel`

If the topic is genuinely ambiguous, ask the user **one** clarifying question before proceeding. Otherwise pick the slug silently.

---

## Phase 2: Write (or update) the memory

Check if a memory with that slug already exists by calling `mcp__serena__list_memories`. The returned list has each memory's `name` field.

**If slug is NEW:**

Call `mcp__serena__write_memory` with:
```
name: <slug>
content: $ARGUMENTS
```

**If slug already exists:**

Read the existing memory via `mcp__serena__read_memory({ name: <slug> })`. Append the new fact as an `## Update YYYY-MM-DD` section, then write back via `mcp__serena__write_memory`:

```
<existing content>

## Update YYYY-MM-DD

$ARGUMENTS
```

(Use today's date in ISO format.)

---

## Phase 3: Confirm

Print:

```
✓ Wrote memory: <slug>
  Path: .serena/memories/<slug>.md
  Action: <created|appended-update>
```

---

## Error handling summary

| Failure | Action |
|---|---|
| Serena MCP unreachable | Stop with install instructions (Phase 0) |
| `mcp__serena__write_memory` fails | Print error verbatim, exit non-zero |
| User declines to clarify ambiguous slug | Ask once more; if still unclear, abort with "Couldn't derive a clear slug — try /remember with more specific phrasing" |

## Constraints

- This command MUST NOT run any phase from `/feature` or `/improve` (no critic, no TDD, no git).
- This command does NOT commit anything to git — Serena writes to `.serena/memories/` directly. The user can commit those files manually if they want them tracked.
- This command does NOT update `docs/architecture.md`, `docs/features.md`, or `.claude/lessons/`.
````

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/remember.md
test -f "$F" && echo EXISTS
head -5 "$F" | grep -q "^description:" && echo "frontmatter description OK"
head -5 "$F" | grep -q "^argument-hint:" && echo "frontmatter argument-hint OK"
for phase in "Phase 0:" "Phase 1:" "Phase 2:" "Phase 3:"; do
  grep -q "^## $phase" "$F" && echo "  $phase present"
done
grep -q "mcp__serena__write_memory" "$F" && echo "uses write_memory MCP tool"
grep -q "mcp__serena__list_memories" "$F" && echo "uses list_memories MCP tool"
grep -q "mcp__serena__read_memory" "$F" && echo "uses read_memory MCP tool (for append-update flow)"
grep -q "kebab-case" "$F" && echo "slug rule documented"
grep -q "## Update YYYY-MM-DD" "$F" && echo "append-update protocol present"
```
Expected: 11 confirmation lines.

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add commands/remember.md
git commit -m "feat(/remember): add 7th user-facing command for manual memory capture

Wraps Serena's mcp__serena__write_memory. Phase 0 pre-flight checks MCP
reachability with install instructions on failure. Phase 1 derives a kebab-case
slug from the argument. Phase 2 writes new or appends ## Update YYYY-MM-DD
section to existing. No critic, no plan, no git commit — pure utility."
```

---

## Task 3: Update `commands/init.md` Phase 1 — add Serena auto-install

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/init.md`

The current Phase 1 detects missing of 4 plugins and the `bd` CLI. We add Serena detection and install logic to the same phase.

- [ ] **Step 1: Read current Phase 1 to locate insertion point**

```bash
grep -n "^## Phase " /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/init.md
```
Expected: 8 phase headers (Phase 0 through Phase 7). Note the line numbers of `## Phase 1:` and `## Phase 2:` — the Serena block goes inside Phase 1, after the `bd` CLI detection block, before `---` and `## Phase 2:`.

- [ ] **Step 2: Add Serena detection + install block at end of Phase 1**

Use the Edit tool to find the existing `bd` CLI detection block (near the end of Phase 1, before `---`). The current end of Phase 1 looks roughly like:

```markdown
4. **Detect `bd` CLI (separate from beads plugin):**
   ```bash
   command -v bd >/dev/null 2>&1 && echo PRESENT || echo MISSING
   ```
   If `MISSING`, print:
   ```
   beads CLI not found. Install it manually: brew install beads
   Continuing without bd init — task tracking will not work until bd is installed.
   ```

---
```

Add a new section **5** AFTER the `bd` detection (and before the `---`):

```markdown

5. **Detect `uv` and Serena (separate from plugins):**

   ```bash
   command -v uv >/dev/null 2>&1 && echo UV_PRESENT || echo UV_MISSING
   ```

   If `UV_PRESENT`:
   - Detect Serena CLI install: `uv tool list 2>/dev/null | grep -q "^serena-agent" && echo SERENA_INSTALLED || echo SERENA_NOT_INSTALLED`
   - Detect Serena MCP registration: `claude mcp list 2>/dev/null | grep -q "^serena:" && echo SERENA_MCP_REGISTERED || echo SERENA_MCP_NOT_REGISTERED`
   - If either is missing, add this line to the consent prompt list (alongside the missing plugins):
     ```
     - serena-agent (Python tool via uv) + MCP registration
     ```
   - On consent (`y`):
     ```bash
     # Install if not installed
     if ! uv tool list 2>/dev/null | grep -q "^serena-agent"; then
       uv tool install -p 3.13 serena-agent@latest --prerelease=allow 2>&1 | tail -3
     fi

     # Initialize project's .serena/ directory (idempotent)
     serena init </dev/null 2>&1 | head -10

     # Register MCP server at user scope (idempotent — skip if already registered)
     if ! claude mcp list 2>/dev/null | grep -q "^serena:"; then
       claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd 2>&1 | tail -3
     fi
     ```
   - On any failure: print warning with the exact failed command, continue.

   If `UV_MISSING`, print:
   ```
   uv not installed. Install: brew install uv  (or  curl -LsSf https://astral.sh/uv/install.sh | sh)
   Then re-enable Serena in this project:
     uv tool install -p 3.13 serena-agent@latest --prerelease=allow
     serena init
     claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
   Continuing without Serena — /remember and memory-aware ground phases will be disabled.
   ```

---
```

(Indentation matches the existing items 1-4 of Phase 1.)

- [ ] **Step 3: Update the consent prompt template earlier in Phase 1**

The current consent prompt says:
```
About to install missing prerequisite plugins: <comma-separated names>. Proceed? [y/n]
```

Update to:
```
About to install missing prerequisites:
  - <missing plugin 1>
  - <missing plugin 2>
  - ...
  - serena-agent (Python tool via uv) + MCP registration   [if uv present and Serena missing]
Proceed? [y/n]
```

Find and update this section in `init.md` Phase 1.

- [ ] **Step 4: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/init.md
grep -q "uv tool install -p 3.13 serena-agent" "$F" && echo "install command present"
grep -q "claude mcp add --scope user serena" "$F" && echo "MCP add command present"
grep -q "serena start-mcp-server --context claude-code --project-from-cwd" "$F" && echo "exact MCP launch flags present"
grep -q "serena init" "$F" && echo "serena init step present"
grep -q "UV_PRESENT\|UV_MISSING" "$F" && echo "uv detection logic present"
grep -q "SERENA_INSTALLED\|SERENA_NOT_INSTALLED" "$F" && echo "Serena detection logic present"
grep -q "About to install missing prerequisites:" "$F" && echo "updated consent prompt present"
```
Expected: 7 confirmation lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add commands/init.md
git commit -m "feat(/init): auto-install Serena via uv (Phase 1)

Adds detection for uv + serena-agent + MCP registration. On consent:
runs 'uv tool install -p 3.13 serena-agent@latest --prerelease=allow',
'serena init', and 'claude mcp add --scope user serena -- serena
start-mcp-server --context claude-code --project-from-cwd'. If uv is
missing, prints manual install instructions and continues with Serena
disabled. Idempotent for repeat runs."
```

---

## Task 4: Update `agents/senior-critic.md` — memory suggestion behavior

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/agents/senior-critic.md`

- [ ] **Step 1: Read the current file to locate the output template section**

```bash
grep -n "## Output format\|^## Lessons applied\|^## What you do NOT do" /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/agents/senior-critic.md
```
Identify the section that contains the output template (the markdown code block showing the report structure).

- [ ] **Step 2: Add new output section "Memories to capture (suggested)"**

Inside the agent's output template (the markdown code block in the "Output format" section), add a new section AFTER `## Lessons NOT applied` and BEFORE the closing ```` ``` ````:

```markdown
## Memories to capture (suggested)
- `<slug>`: <one-line summary> — <why it's stable knowledge worth remembering>
- ...

(If none: "None.")
```

Use the Edit tool. The current output template ends with:

```
## Lessons NOT applied (and why)
- `<lesson-filename>` — <one sentence: why this didn't apply>
- ...

(Only list lessons whose trigger plausibly matched but you decided didn't apply on inspection. Skip ones that obviously don't apply.)
```

(then a closing ```` ``` ````)

After "(Only list lessons..." paragraph and before the closing fence, insert:

```

## Memories to capture (suggested)
- `<slug>`: <one-line summary> — <why it's stable knowledge worth remembering>
- ...

(If none: "None.")
```

- [ ] **Step 3: Add the "Memory suggestions" behavior section**

Find a logical spot near the end of the agent file (e.g. after the existing tone/output guidance, before "What you do NOT do"). Insert this new section:

```markdown
## Memory suggestions

After listing your findings, decide if any non-obvious knowledge surfaced during this work would help future agents. Suggest a memory if:

- A non-obvious design choice with rationale (e.g. "auth uses session cookies not JWT because the backend is server-rendered")
- A project convention not enforced by tooling (e.g. "we always handle pagination in the controller, never the model")
- A domain-specific fact (e.g. "users are billed in EUR")

Do NOT suggest a memory for:
- Bugs (those are lessons, not memories)
- Tasks (those are beads)
- External library docs (those are Context7)
- Anything already in `docs/architecture.md` or `docs/features.md`

**Slug rules:** 2-4 kebab-case words derived from the topic (not the symptom).

**Aim for 0-2 memory suggestions per gate. Quality over quantity.** A gate with no memory suggestions is a successful gate.
```

- [ ] **Step 4: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/agents/senior-critic.md
grep -q "## Memories to capture (suggested)" "$F" && echo "output template section added"
grep -q "## Memory suggestions" "$F" && echo "behavior section added"
grep -q "0-2 memory suggestions per gate" "$F" && echo "quantity guidance present"
grep -q "Bugs (those are lessons" "$F" && echo "boundary with lessons documented"
grep -q "kebab-case" "$F" && echo "slug rule documented"
```
Expected: 5 confirmation lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add agents/senior-critic.md
git commit -m "feat(senior-critic): add memory suggestion behavior

The critic now adds a 'Memories to capture (suggested)' section to its
report. Heuristics: design rationale, project conventions, domain facts.
Explicit boundaries with lessons (bugs), beads (tasks), Context7 (libs),
master plan (architecture/features). Aim for 0-2 suggestions per gate."
```

---

## Task 5: Update `commands/feature.md` — read memories in Phase 1, write at Phase 8

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/feature.md`

- [ ] **Step 1: Locate Phase 1 (Ground) section**

```bash
grep -n "^## Phase 1:" /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/feature.md
```

- [ ] **Step 2: Add memory loading step to Phase 1 (Ground)**

In Phase 1, find the existing list of "Read in full:" items (architecture.md, features.md, roadmap.md, lessons). After that block, insert:

```markdown

**Memory grounding (NEW):**

Call `mcp__serena__list_memories` to retrieve all memory names. For each name whose slug substring-matches the feature description (`$ARGUMENTS`) OR matches files plausibly affected by this work, call `mcp__serena__read_memory({ name: <name> })` and incorporate its content into your context.

Add a `Memory grounding: N memories loaded (<comma-separated names>)` line to the internal ground summary. If `list_memories` fails (Serena MCP not running), skip this step silently with one note: `Memory grounding: skipped (Serena unavailable)`.
```

Use the Edit tool to insert this after the existing reads.

- [ ] **Step 3: Locate Phase 8 (Critic gate-2) section**

```bash
grep -n "^## Phase 8:" /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/feature.md
```

- [ ] **Step 4: Add memory auto-write to Phase 8**

In Phase 8, after the critic returns its summary line, insert this new step BEFORE the existing user decision (continue/address/override):

```markdown

**Auto-write suggested memories (NEW):**

Read the critic's saved report file (path returned in the summary line). Parse the section beginning with `## Memories to capture (suggested)`. For each bullet entry of the form `` - `<slug>`: <summary> — <reason>``:

```bash
# For each suggested memory:
mcp__serena__write_memory({
  name: "<slug>",
  content: "<summary>\n\nCaptured by senior-critic at gate-2 of /feature \"$ARGUMENTS\" on YYYY-MM-DD.\n\n<reason>"
})
```

If a memory with that slug already exists (check via `mcp__serena__list_memories`), append `## Update YYYY-MM-DD` section to it instead of overwriting.

If `mcp__serena__write_memory` fails (Serena MCP not running), warn once with the slug and continue — do NOT block the pipeline.

Print a one-line summary: `Memories captured: <N> new, <M> updated, <P> skipped`.
```

- [ ] **Step 5: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/feature.md
grep -q "mcp__serena__list_memories" "$F" && echo "list_memories used in ground"
grep -q "mcp__serena__read_memory" "$F" && echo "read_memory used in ground"
grep -q "mcp__serena__write_memory" "$F" && echo "write_memory used in gate-2"
grep -q "Memory grounding:" "$F" && echo "ground summary line documented"
grep -q "Memories to capture (suggested)" "$F" && echo "critic section parser referenced"
grep -q "Memories captured: <N> new" "$F" && echo "post-write summary line present"
grep -q "skipped (Serena unavailable)" "$F" && echo "graceful degradation present"
```
Expected: 7 confirmation lines.

- [ ] **Step 6: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add commands/feature.md
git commit -m "feat(/feature): add Serena memory hooks (read in ground, write at gate-2)

Phase 1 (ground): list memories and read those whose slug matches the
feature description or affected files. Phase 8 (critic gate-2): parse
'Memories to capture (suggested)' from the critic report and auto-write
new entries (or append ## Update YYYY-MM-DD to existing). Graceful
degradation if Serena MCP unavailable — pipeline never blocked."
```

---

## Task 6: Update `commands/improve.md` — same memory hooks as `/feature`

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/improve.md`

`/improve.md` delegates to `/feature.md` for most pipeline content but documents differences inline. Memory hooks apply identically.

- [ ] **Step 1: Inspect current improve.md structure**

```bash
grep -n "^## " /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/improve.md
```

- [ ] **Step 2: Add a new sentence to the "Phases 2-12: Same as /feature.md" section**

Find the section that says "Phases 2-12: Same as `/feature.md`" (around the differences callout for Phase 5/8/11). Add a new bullet to the differences list:

```markdown
- **Memory hooks**: Same as `/feature.md` — Phase 1 reads relevant Serena memories; Phase 8 auto-writes critic-suggested memories.
```

- [ ] **Step 3: Add memory-grounding line to Phase 1 (Ground - improve-flavored)**

In `improve.md`'s Phase 1 (which has its own improve-flavored ground steps), add after the standard ground steps:

```markdown

**Memory grounding (NEW):** Same as `/feature.md` Phase 1 — call `mcp__serena__list_memories` and `mcp__serena__read_memory` for slug matches. Add `Memory grounding: N memories loaded` line to the internal summary.
```

- [ ] **Step 4: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/improve.md
grep -q "Memory hooks" "$F" && echo "memory hooks differences documented"
grep -q "mcp__serena__list_memories" "$F" && echo "list_memories referenced"
grep -q "Same as \`/feature.md\` Phase 1" "$F" && echo "delegates to feature for memory pattern"
```
Expected: 3 confirmation lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add commands/improve.md
git commit -m "feat(/improve): inherit Serena memory hooks from /feature

Phase 1 reads matching memories; Phase 8 auto-writes critic-suggested
memories. Same logic as /feature — improve.md documents the difference
in its 'Phases 2-12: Same as /feature.md' section."
```

---

## Task 7: Update `commands/plan-improve.md` — write memories from critic

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/plan-improve.md`

`/plan-improve` already invokes the critic at Phase 5. We add the same memory parse + write logic.

- [ ] **Step 1: Locate Phase 5 (Critic review)**

```bash
grep -n "^## Phase 5:" /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/plan-improve.md
```

- [ ] **Step 2: Add memory auto-write step after critic returns**

In Phase 5, after the critic saves its report and returns its summary, before the user-decision step, insert:

```markdown

**Auto-write suggested memories (NEW):**

Same protocol as `/feature.md` Phase 8: parse the critic report's `## Memories to capture (suggested)` section. For each `` - `<slug>`: <summary> — <reason> `` line, call `mcp__serena__write_memory` (new) or append `## Update YYYY-MM-DD` (existing). Source line in the memory: `Captured by senior-critic at gate-1 of /plan-improve "$ARGUMENTS" on YYYY-MM-DD`.

If Serena MCP unavailable: warn, skip, continue.

Print: `Memories captured: <N> new, <M> updated, <P> skipped`.
```

- [ ] **Step 3: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/plan-improve.md
grep -q "mcp__serena__write_memory" "$F" && echo "write_memory used"
grep -q "Memories to capture (suggested)" "$F" && echo "critic parser referenced"
grep -q "gate-1 of /plan-improve" "$F" && echo "source attribution present"
```
Expected: 3 confirmation lines.

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add commands/plan-improve.md
git commit -m "feat(/plan-improve): auto-write critic-suggested memories at Phase 5

Same protocol as /feature.md Phase 8 but at gate-1 (post-spec equivalent).
Captures any memories the critic suggests during plan refinement."
```

---

## Task 8: Update `assets/templates/CLAUDE.md` — Hard Rule #7 + Memories section + 7-command table

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/CLAUDE.md`

This is the **per-project** CLAUDE.md template — what `/init` writes into a user's new project. NOT the plugin's own CLAUDE.md (that one ships at the plugin root and is for contributors).

- [ ] **Step 1: Update the user-facing commands table from 6 to 7 rows**

Find the table starting with `| Command | When |`. The current 6 rows are init, plan-improve, feature, improve, fix, lesson. Add as the 7th row:

```markdown
| `/remember "<fact>"` | Capture a project-specific fact to Serena memory (rare) |
```

- [ ] **Step 2: Add Hard Rule #7**

The current Hard Rules section ends at rule 6 (the GREEN cycle commits + /fix lesson). Add rule 7:

```markdown
7. **Before starting `/feature` or `/improve`:** list `.serena/memories/` and read any memory whose name matches the work's topic or affected files. Cite the memory name when applying its content.
```

- [ ] **Step 3: Add the new "Memories (Serena)" section**

After the existing "## Lessons" section, add:

```markdown
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
```

- [ ] **Step 4: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/CLAUDE.md
grep -q "/remember \"<fact>\"" "$F" && echo "/remember in commands table"
grep -q "^7\. \*\*Before starting" "$F" && echo "Hard Rule #7 added"
grep -q "## Memories (Serena)" "$F" && echo "Memories section added"
grep -q "billed in EUR" "$F" && echo "examples included"
grep -q "NOT written by \`/fix\`" "$F" && echo "boundary with /fix documented"
```
Expected: 5 confirmation lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add assets/templates/CLAUDE.md
git commit -m "feat(template/CLAUDE.md): document Serena memory layer

Adds /remember to the 7-command table, Hard Rule #7 (read matching
memories before /feature or /improve), and a new Memories (Serena)
section explaining the layer's role and boundaries."
```

---

## Task 9: Update `assets/templates/PIPELINE.md` — 5-layer context table

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/PIPELINE.md`

- [ ] **Step 1: Find the right insertion point**

```bash
grep -n "^## " /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/PIPELINE.md
```

- [ ] **Step 2: Add a new "Context layers" section**

After the existing "## Lessons system" section (or anywhere logical near the end before "## Edge cases"), add:

```markdown
## Context layers

The pipeline reads from 5 context layers:

| Layer | Storage | Stores | Read in | Written in |
|---|---|---|---|---|
| **Beads** | `.beads/` | tasks + dependencies | every `bd ready` | every command |
| **Lessons** | `.claude/lessons/*.md` | bug prevention rules | every phase (lesson trigger match) | `/fix`, `/lesson` |
| **Master Plan** | `docs/{architecture,features,roadmap}.md` | what+how+priorities | ground phase | `/init`, `/plan-improve`, `/feature` (features.md only) |
| **Context7** | live MCP query | external library docs | ground phase | n/a (read-only) |
| **Serena memory** | `.serena/memories/*.md` | project conventions + design decisions | `/feature`/`/improve` ground | senior-critic at gate-2 (gate-1 for `/plan-improve`), `/remember` |

The layers do NOT overlap by design:
- Bug? → lesson
- Task? → bead
- Architectural decision? → master plan (`architecture.md`)
- External library quirk? → Context7 (or Serena memory if it's PROJECT-specific use of that library)
- Project convention or ambient knowledge? → Serena memory
```

- [ ] **Step 3: Update the 7-command table**

Find the existing 6-command table and add the 7th row:

```markdown
### `/remember "<fact>"`
Capture a project-specific fact to Serena memory. Plain wrapper around `mcp__serena__write_memory`. Used rarely — most memories come automatically from senior-critic at gate-2.
```

- [ ] **Step 4: Update the internal-phases table to include memory steps**

If `PIPELINE.md` has an internal-phases table for `/feature` (the 11 numbered phases), update:
- Phase 1 (ground): note that it now includes Serena memory loading
- Phase 8 (critic gate-2): note that it now includes auto-write of suggested memories

Use the Edit tool to add a brief note like `+ load matching memories` to the Phase 1 row and `+ auto-write suggested memories` to the Phase 8 row.

- [ ] **Step 5: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/PIPELINE.md
grep -q "^## Context layers" "$F" && echo "Context layers section added"
grep -q "Serena memory" "$F" && echo "Serena layer documented"
grep -q "/remember" "$F" && echo "/remember in command list"
grep -q "load matching memories\|memories loaded" "$F" && echo "ground phase memory step noted"
```
Expected: 4 confirmation lines.

- [ ] **Step 6: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add assets/templates/PIPELINE.md
git commit -m "docs(template/PIPELINE.md): add Serena as 5th context layer

New 'Context layers' section with the full 5-layer table. Adds /remember
to the command reference. Updates internal phases to note memory
read/write steps."
```

---

## Task 10: Update `README.md` (English) — 7 commands + Serena prereq

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/README.md`

- [ ] **Step 1: Update the "What you get" commands table**

Find the table with the 6 commands. Add as the 7th row:

```markdown
| `/remember "<fact>"` | Capture a project-specific fact to Serena memory (rare) |
```

- [ ] **Step 2: Update Prerequisites section**

The current Prerequisites section lists 4 plugins + `bd` CLI. Add:

```markdown
- **`uv`** (Python tool manager): `brew install uv` (macOS) or `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **`serena-agent`** (Python tool, auto-installed by `/init` via `uv` if `uv` is present)
```

And add the Serena MCP install command:

```markdown
After `/init`, the Serena MCP server is registered globally:
`claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd`
```

- [ ] **Step 3: Update the "Architecture" section**

Add a bullet to the per-project files list:

```markdown
- `.serena/memories/` — Serena memory layer (stable project knowledge: conventions + design decisions)
```

And add a sentence to the architecture description mentioning "memory layer".

- [ ] **Step 4: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/README.md
grep -q "/remember" "$F" && echo "/remember added to commands table"
grep -q "uv tool manager\|brew install uv\|astral.sh/uv" "$F" && echo "uv prereq added"
grep -q "serena-agent" "$F" && echo "Serena prereq added"
grep -q ".serena/memories" "$F" && echo "memory directory mentioned"
grep -q "claude mcp add --scope user serena" "$F" && echo "MCP add command documented"
```
Expected: 5 confirmation lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add README.md
git commit -m "docs(README): document /remember and Serena prereq for v0.2.0"
```

---

## Task 11: Update `README_RU.md` (Russian) — mirror the changes from Task 10

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/README_RU.md`

- [ ] **Step 1: Add 7th row to the commands table**

```markdown
| `/remember "<факт>"` | Записать факт о проекте в память Serena (редко) |
```

- [ ] **Step 2: Update Prerequisites section (Зависимости)**

```markdown
- **`uv`** (менеджер Python-инструментов): `brew install uv` (macOS) или `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **`serena-agent`** (Python-инструмент, автоматически установится `/init` через `uv` если `uv` присутствует)
```

And:

```markdown
После `/init`, Serena MCP-сервер регистрируется глобально:
`claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd`
```

- [ ] **Step 3: Update Architecture (Архитектура) section**

```markdown
- `.serena/memories/` — слой памяти Serena (стабильные знания о проекте: конвенции + решения)
```

- [ ] **Step 4: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/README_RU.md
grep -q "/remember" "$F" && echo "/remember added"
grep -q "uv\|astral.sh" "$F" && echo "uv prereq added"
grep -q "serena-agent\|Serena" "$F" && echo "Serena prereq added"
grep -q ".serena/memories" "$F" && echo "memory dir mentioned"
grep -q "claude mcp add --scope user serena" "$F" && echo "MCP command documented"
```
Expected: 5 confirmation lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add README_RU.md
git commit -m "docs(README_RU): document /remember and Serena prereq (v0.2.0)"
```

---

## Task 12: Update plugin's contributor `CLAUDE.md` + `docs/DESIGN_NOTES.md`

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/CLAUDE.md`
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs/DESIGN_NOTES.md`

- [ ] **Step 1: Add a contributor rule about Serena memory**

In `CLAUDE.md` (the plugin's contributor file at root), under "Hard rules for plugin changes", add:

```markdown
7. **Serena memory is the 5th context layer.** Any change to `commands/feature.md`, `commands/improve.md`, `commands/plan-improve.md`, or `agents/senior-critic.md` must keep the memory read/write logic intact (Phase 1 ground reads memories; gates auto-write suggested memories from the critic). Do not duplicate memory writes across multiple commands.
```

- [ ] **Step 2: Update version policy in `CLAUDE.md`**

Find the existing "Versioning policy" section. Add a note:

```markdown
- v0.2.0 adds Serena memory integration; new prereq is `uv` + `serena-agent` (auto-installed by `/init`)
```

- [ ] **Step 3: Add Serena spec link to `docs/DESIGN_NOTES.md`**

Find the bullet list at the top of `DESIGN_NOTES.md` (where the v0.1.0 specs are linked). Add:

```markdown
- **Serena memory integration (v0.2.0)** — see the spec at `project_template/docs/superpowers/specs/2026-04-25-serena-memory-integration.md` for the full design (5-layer context model, /remember command, critic-driven auto-capture).
```

- [ ] **Step 4: Verify**

```bash
F1=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/CLAUDE.md
F2=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs/DESIGN_NOTES.md
grep -q "Serena memory is the 5th context layer" "$F1" && echo "contributor rule added"
grep -q "v0.2.0 adds Serena" "$F1" && echo "version policy note added"
grep -q "Serena memory integration (v0.2.0)" "$F2" && echo "spec linked from DESIGN_NOTES"
```
Expected: 3 confirmation lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add CLAUDE.md docs/DESIGN_NOTES.md
git commit -m "docs(contributor): document Serena memory rule and link v0.2.0 spec"
```

---

## Task 13: Bump version 0.1.0 → 0.2.0 in both manifests

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/plugin.json`
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/marketplace.json`

- [ ] **Step 1: Update plugin.json version field**

Use the Edit tool to change `"version": "0.1.0"` to `"version": "0.2.0"`.

- [ ] **Step 2: Update marketplace.json version field**

Use the Edit tool to change the inner `"version": "0.1.0"` (inside `plugins[0]`) to `"version": "0.2.0"`.

- [ ] **Step 3: Verify**

```bash
python3 -c "
import json
p = json.load(open('/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/plugin.json'))
m = json.load(open('/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/marketplace.json'))
assert p['version'] == '0.2.0', f'plugin.json wrong: {p[\"version\"]}'
assert m['plugins'][0]['version'] == '0.2.0', f'marketplace.json wrong: {m[\"plugins\"][0][\"version\"]}'
print('Both bumped to 0.2.0')
"
```
Expected: `Both bumped to 0.2.0`

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: bump version 0.1.0 → 0.2.0 (Serena memory integration)"
```

---

## Task 14: Local reinstall + smoke test

**Files:** none modified — this task verifies the plugin works locally before publishing.

- [ ] **Step 1: Remove the GitHub-installed marketplace entry**

```bash
claude plugin marketplace remove ai-pipeline-marketplace 2>&1 | head -3
```

- [ ] **Step 2: Add the local-path marketplace**

```bash
claude plugin marketplace add /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin 2>&1 | tail -3
```

- [ ] **Step 3: Reinstall**

```bash
claude plugin install ai-pipeline@ai-pipeline-marketplace 2>&1 | tail -3
```

- [ ] **Step 4: Verify cache reflects v0.2.0**

```bash
ls "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/" 2>&1
```
Expected: contains `0.2.0/` directory.

- [ ] **Step 5: Verify the new command file is present**

```bash
ASSETS_PATH=$(ls -d "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/"*/ 2>/dev/null | sort -V | tail -1)
ls "$ASSETS_PATH/commands/" | grep "remember.md" && echo "  ✓ remember.md present in v0.2.0 cache"
```
Expected: `remember.md` listed.

- [ ] **Step 6: Manual smoke test (user instruction)**

Tell the user:

```
PB6 (smoke test) — manual user steps:

In a fresh terminal:
  mkdir /tmp/serena-smoke-$$ && cd /tmp/serena-smoke-$$
  claude

Inside Claude Code:
  > /help
    Confirm 7 commands appear (init, plan-improve, feature, improve, fix, lesson, remember).
  > /init "test app for serena"
    Approve auto-install when prompted (uv should already be installed).
    Answer the 3 questions.
    Confirm bootstrap report includes Serena setup confirmation.
  > /remember "test app uses snake_case for db cols"
    Confirm "Wrote memory: <slug>" message and .serena/memories/<slug>.md exists.
  > /exit

Then in shell:
  ls /tmp/serena-smoke-*/.serena/memories/
  cat /tmp/serena-smoke-*/.serena/memories/*.md

Cleanup:
  rm -rf /tmp/serena-smoke-*
```

Wait for the user to report back.

- [ ] **Step 7: No commit (verification only)**

---

## Task 15: Push v0.2.0 to GitHub + tag

**Files:** none modified — publishes to the existing remote.

- [ ] **Step 1: Verify clean working tree**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git status --porcelain | wc -l | tr -d ' '
```
Expected: `0` (everything committed).

- [ ] **Step 2: Show the diff that will be pushed**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git log --oneline origin/main..HEAD
```
Expected: a list of the 12-13 commits added since v0.1.0.

- [ ] **Step 3: Confirm with user before pushing**

Print:

```
About to push N commits to https://github.com/easyhex/ai-pipeline-plugin (main branch).
This makes v0.2.0 changes public.
Proceed? [y/n]
```

Wait for `y`.

- [ ] **Step 4: Push main**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git push origin main 2>&1 | tail -3
```

- [ ] **Step 5: Tag v0.2.0**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git tag -a v0.2.0 -m "Release 0.2.0 — Serena memory integration (5th context layer + /remember command)"
git push origin v0.2.0 2>&1 | tail -3
```

- [ ] **Step 6: Verify install from GitHub fetches v0.2.0**

```bash
# Force a fresh clone by removing local cache
rm -rf "$HOME/.claude/plugins/cache/ai-pipeline-marketplace"

# Remove and re-add as github (the URL form may have changed; use owner/repo per the v0.1.0 fix)
claude plugin marketplace remove ai-pipeline-marketplace 2>&1 | head -3
claude plugin marketplace add easyhex/ai-pipeline-plugin 2>&1 | tail -3
claude plugin install ai-pipeline@ai-pipeline-marketplace 2>&1 | tail -3

# Verify v0.2.0 in cache
ls "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/" | grep "0.2.0" && echo "  ✓ v0.2.0 fetched from GitHub"
ls "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/0.2.0/commands/" | grep "remember.md" && echo "  ✓ remember.md in published v0.2.0"
```
Expected: both `✓` lines.

- [ ] **Step 7: No commit (publish action only)**

---

## Self-review checklist (run by the implementing agent)

After completing all 15 tasks:

1. **Spec coverage:**
   - §3 (5-layer context model) — Tasks 8 (template CLAUDE.md), 9 (PIPELINE.md), 10/11 (READMEs) ✓
   - §4 (`/remember` command) — Task 2 ✓
   - §5 (`/init` Phase 1 changes) — Task 3 ✓
   - §6 (memory hooks in feature/improve/plan-improve) — Tasks 5, 6, 7 ✓
   - §7 (senior-critic memory section) — Task 4 ✓
   - §8 (template CLAUDE.md updates) — Task 8 ✓
   - §9 (PIPELINE.md updates) — Task 9 ✓
   - §10 (settings.json — no change needed; documented in PIPELINE.md) — Task 9 covers it ✓
   - §11 (README EN+RU) — Tasks 10, 11 ✓
   - §12 (contributor CLAUDE.md) — Task 12 ✓
   - §13 (DESIGN_NOTES.md link) — Task 12 ✓
   - §14 (version bump) — Task 13 ✓
   - §15 (acceptance criteria) — Task 14 verifies ✓
   - §16 (risk: serena init interactivity) — Task 1 probes ✓
   - §18 (Definition of Done) — all 15 items mapped ✓

2. **Placeholder scan:** every task has concrete content. No "TBD".

3. **Type/name consistency:**
   - `mcp__serena__write_memory` / `read_memory` / `list_memories` consistent across Tasks 2, 5, 6, 7 ✓
   - Slug rules ("kebab-case", "2-4 words") consistent across Tasks 2, 4 ✓
   - `serena start-mcp-server --context claude-code --project-from-cwd` consistent across Tasks 3, 10, 11 ✓
   - Version `0.2.0` consistent across Tasks 13, 15 ✓
   - `--scope user` consistent across Tasks 3, 10, 11 ✓
   - `## Update YYYY-MM-DD` append protocol consistent across Tasks 2, 5, 6, 7 ✓

---

## Post-implementation handoff (for the user)

After all 15 tasks complete:

```
✓ ai-pipeline plugin v0.2.0 published.

Repo:    https://github.com/easyhex/ai-pipeline-plugin
Version: 0.2.0
Tag:     v0.2.0

New in v0.2.0:
  - 7th command: /remember "<fact>"
  - Serena auto-install via uv in /init
  - Senior-critic auto-suggests memories at gates
  - Memory read in /feature and /improve ground phase
  - 5-layer context model (Beads + Lessons + Master Plan + Context7 + Serena memory)

Update existing v0.1.0 installs:
  claude plugin install ai-pipeline@ai-pipeline-marketplace

For v0.1.0 projects that want Serena retrofit:
  uv tool install -p 3.13 serena-agent@latest --prerelease=allow
  serena init      # in the project directory
  claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
```
