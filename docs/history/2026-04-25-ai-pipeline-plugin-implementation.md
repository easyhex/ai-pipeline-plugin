# AI Pipeline Plugin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a native Claude Code plugin (`ai-pipeline`) at `github.com/easyhex/ai-pipeline-plugin` that installs the 6-command AI development pipeline globally and bootstraps any new project with `/init "<description>"`.

**Architecture:** Single-plugin repo with `commands/` (auto-loaded slash commands), `agents/` (auto-loaded subagents), and `assets/templates/` (per-project files written into user's cwd by `/init`). Plugin manifest at `.claude-plugin/plugin.json`; marketplace entry at `.claude-plugin/marketplace.json`. The 5 non-`/init` commands and the `senior-critic` agent are copied **verbatim** from the verified `project_template/` implementation. Only `/init` is rewritten.

**Tech Stack:** Markdown command files, JSON manifests, Claude Code plugin system. No programming-language code.

**Reference spec:** `~/Documents/00_CODE/project_template/docs/superpowers/specs/2026-04-25-ai-pipeline-plugin-design.md`

**Working directory:** All paths in this plan are absolute. New plugin lives at `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/`. Source for migrations is `/Users/vladislav/Documents/00_CODE/project_template/`.

**Verified plugin schema (from inspecting installed plugins):**
- `agents/` is a top-level directory (e.g. `superpowers/agents/code-reviewer.md`)
- Agent file format: YAML frontmatter with `name`, `description`, optionally `model: inherit`, then prompt
- `plugin.json` fields: `name`, `description`, `version`, `author` (object with `name` and `url`), `repository` (URL string), `license`, `keywords` (array)
- `marketplace.json` fields: `name`, `description`, `owner` (object with `name`), `plugins` (array of `{name, source, description, version}`)
- Plugin install location: `~/.claude/plugins/cache/<marketplace-name>/<plugin-name>/<version>/`

---

## File structure to be produced

```
/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/
├── .claude-plugin/
│   ├── plugin.json                       # Task 2
│   └── marketplace.json                  # Task 3
├── commands/
│   ├── init.md                           # Task 9 (REWRITTEN)
│   ├── plan-improve.md                   # Task 5 (verbatim copy)
│   ├── feature.md                        # Task 5 (verbatim copy)
│   ├── improve.md                        # Task 5 (verbatim copy)
│   ├── fix.md                            # Task 5 (verbatim copy)
│   └── lesson.md                         # Task 5 (verbatim copy)
├── agents/
│   └── senior-critic.md                  # Task 6 (verbatim copy)
├── assets/
│   └── templates/
│       ├── CLAUDE.md                     # Task 7 (copy from project_template)
│       ├── architecture.md               # Task 7
│       ├── features.md                   # Task 7
│       ├── roadmap.md                    # Task 7
│       ├── PIPELINE.md                   # Task 7
│       ├── LESSON_FORMAT.md              # Task 7
│       ├── gitignore                     # Task 7 (renamed; /init writes as .gitignore)
│       └── settings.json                 # Task 7 then Task 8 (enable plugin)
├── docs/
│   ├── WORKFLOW_GUIDE_RU.md              # Task 11
│   └── DESIGN_NOTES.md                   # Task 13
├── CLAUDE.md                             # Task 12 (plugin contributor rules)
├── README.md                             # Task 10
├── README_RU.md                          # Task 11
├── LICENSE                               # Task 4 (MIT)
├── settings.example.json                 # Task 13
└── .gitignore                            # Task 4
```

---

## Verification approach

The plugin's artifacts are configuration and prompt files. "Tests" mean: file exists, JSON parses, frontmatter matches, content is verbatim where it should be.

**Two end-to-end tests:**
- **Task 14** — local install: `claude plugin marketplace add /local/path` then verify the 6 commands appear in `/help`
- **Task 15** — `/init` in `/tmp/test-app/` and verify all acceptance criteria from spec §12

---

## Task 1: Create plugin repo skeleton

**Files:**
- Create: directory `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/` and all subdirectories

- [ ] **Step 1: Refuse if directory already exists**

```bash
test -d /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin && echo "EXISTS — STOP, decide whether to delete first" || echo "OK — safe to create"
```
Expected: `OK — safe to create`. If `EXISTS`, stop and ask user before proceeding.

- [ ] **Step 2: Create directory tree**

```bash
mkdir -p /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/{.claude-plugin,commands,agents,assets/templates,docs}
```

- [ ] **Step 3: Verify structure**

```bash
find /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin -type d | sort
```
Expected:
```
/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin
/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/agents
/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets
/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates
/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands
/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs
```

- [ ] **Step 4: Initialize git**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git init
git config user.email "nemtsovkz@gmail.com"
git config user.name "easyhex"
```

- [ ] **Step 5: Verify git initialized**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin && git status 2>&1 | head -3
```
Expected output starts with `On branch main` (or `master`) and `No commits yet`.

---

## Task 2: Write `.claude-plugin/plugin.json`

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/plugin.json`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/plugin.json && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content (verified against template-bridge's plugin.json schema):

```json
{
  "name": "ai-pipeline",
  "description": "6-command AI development pipeline (/init, /plan-improve, /feature, /improve, /fix, /lesson) with auto-critic at two gates and a lessons-learned flywheel. Builds on Superpowers, Beads, Context7.",
  "version": "0.1.0",
  "author": {
    "name": "easyhex",
    "url": "https://github.com/easyhex"
  },
  "repository": "https://github.com/easyhex/ai-pipeline-plugin",
  "license": "MIT",
  "keywords": ["pipeline", "tdd", "critic", "lessons", "superpowers", "beads", "claude-code"]
}
```

- [ ] **Step 3: Verify JSON parses + required fields present**

```bash
python3 -c "
import json
p = json.load(open('/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/plugin.json'))
assert p['name'] == 'ai-pipeline', f'bad name: {p[\"name\"]}'
assert p['version'] == '0.1.0', f'bad version: {p[\"version\"]}'
assert p['license'] == 'MIT', f'bad license: {p[\"license\"]}'
assert p['author']['name'] == 'easyhex', 'bad author.name'
assert 'github.com/easyhex' in p['repository'], 'bad repository URL'
print('PASS')
"
```
Expected: `PASS`

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add .claude-plugin/plugin.json
git commit -m "chore: add plugin.json (ai-pipeline 0.1.0)"
```

---

## Task 3: Write `.claude-plugin/marketplace.json`

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/marketplace.json`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/marketplace.json && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content (verified against template-bridge's marketplace.json schema):

```json
{
  "name": "ai-pipeline-marketplace",
  "description": "AI development pipeline plugin: 6 commands, automatic critic, lessons-learned flywheel.",
  "owner": { "name": "easyhex" },
  "plugins": [
    {
      "name": "ai-pipeline",
      "source": "./",
      "description": "6-command AI development pipeline with auto-critic and lessons.",
      "version": "0.1.0"
    }
  ]
}
```

- [ ] **Step 3: Verify**

```bash
python3 -c "
import json
m = json.load(open('/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.claude-plugin/marketplace.json'))
assert m['name'] == 'ai-pipeline-marketplace'
assert m['owner']['name'] == 'easyhex'
assert len(m['plugins']) == 1 and m['plugins'][0]['name'] == 'ai-pipeline'
assert m['plugins'][0]['source'] == './'
print('PASS')
"
```
Expected: `PASS`

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add .claude-plugin/marketplace.json
git commit -m "chore: add marketplace.json"
```

---

## Task 4: Write LICENSE and plugin repo `.gitignore`

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/LICENSE`
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.gitignore`

- [ ] **Step 1: Write LICENSE (MIT)**

Content (standard MIT, current year):

```
MIT License

Copyright (c) 2026 easyhex

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Write `.gitignore` for the plugin repo itself**

Content (this is the plugin REPO's .gitignore, distinct from `assets/templates/gitignore` which ships to user projects):

```
# OS
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
*.swp

# Test scratch
/tmp-test/
.test-cache/

# Local-only Claude state
.claude/cache/
.claude/sessions/
```

- [ ] **Step 3: Verify**

```bash
test -f /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/LICENSE && echo "LICENSE EXISTS"
test -f /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/.gitignore && echo ".gitignore EXISTS"
grep -q "MIT License" /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/LICENSE && echo "MIT confirmed"
grep -q "Copyright (c) 2026 easyhex" /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/LICENSE && echo "copyright correct"
```
Expected: 4 confirmation lines.

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add LICENSE .gitignore
git commit -m "chore: add MIT LICENSE and .gitignore"
```

---

## Task 5: Migrate 5 verbatim command files

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/plan-improve.md` (copy of `/Users/vladislav/Documents/00_CODE/project_template/.claude/commands/plan-improve.md`)
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/feature.md` (copy of source)
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/improve.md` (copy of source)
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/fix.md` (copy of source)
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/lesson.md` (copy of source)

- [ ] **Step 1: Verify source files exist**

```bash
SRC=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands
for f in plan-improve.md feature.md improve.md fix.md lesson.md; do
  test -f "$SRC/$f" && echo "source OK: $f" || echo "MISSING source: $f"
done
```
Expected: 5 lines all `source OK: ...`. If any missing, STOP — depends on `project_template/` from prior implementation being intact.

- [ ] **Step 2: Copy verbatim**

```bash
SRC=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands
DST=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands
for f in plan-improve.md feature.md improve.md fix.md lesson.md; do
  cp "$SRC/$f" "$DST/$f"
done
```

- [ ] **Step 3: Verify byte-for-byte equality**

```bash
SRC=/Users/vladislav/Documents/00_CODE/project_template/.claude/commands
DST=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands
for f in plan-improve.md feature.md improve.md fix.md lesson.md; do
  diff -q "$SRC/$f" "$DST/$f" && echo "identical: $f" || echo "DIFFERS: $f"
done
```
Expected: 5 lines all `identical: ...`

- [ ] **Step 4: Verify command frontmatter intact**

```bash
DST=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands
for f in plan-improve.md feature.md improve.md fix.md lesson.md; do
  head -5 "$DST/$f" | grep -q "^description:" && echo "frontmatter OK: $f" || echo "frontmatter MISSING: $f"
done
```
Expected: 5 `frontmatter OK: ...` lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add commands/plan-improve.md commands/feature.md commands/improve.md commands/fix.md commands/lesson.md
git commit -m "feat: migrate 5 verbatim commands from project_template

- /plan-improve: refine Master Plan
- /feature: full auto pipeline for new functionality
- /improve: full auto pipeline for behavior changes
- /fix: debug + auto-lesson
- /lesson: manual lesson capture"
```

---

## Task 6: Migrate `senior-critic` agent

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/agents/senior-critic.md` (copy of `/Users/vladislav/Documents/00_CODE/project_template/.claude/agents/senior-critic.md`)

- [ ] **Step 1: Verify source exists**

```bash
test -f /Users/vladislav/Documents/00_CODE/project_template/.claude/agents/senior-critic.md && echo "source OK" || echo "MISSING source"
```
Expected: `source OK`

- [ ] **Step 2: Copy**

```bash
cp /Users/vladislav/Documents/00_CODE/project_template/.claude/agents/senior-critic.md \
   /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/agents/senior-critic.md
```

- [ ] **Step 3: Verify byte-for-byte equality**

```bash
diff -q /Users/vladislav/Documents/00_CODE/project_template/.claude/agents/senior-critic.md \
        /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/agents/senior-critic.md \
  && echo "identical"
```
Expected: `identical`

- [ ] **Step 4: Verify agent frontmatter**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/agents/senior-critic.md
head -5 "$F" | grep -q "^name: senior-critic$" && echo "name OK"
head -10 "$F" | grep -q "^description:" && echo "description OK"
head -10 "$F" | grep -q "^tools:" && echo "tools OK"
```
Expected: 3 `OK` lines.

- [ ] **Step 5: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add agents/senior-critic.md
git commit -m "feat: migrate senior-critic agent from project_template"
```

---

## Task 7: Migrate template files to `assets/templates/`

**Files:**
- Create 8 files under `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/`

- [ ] **Step 1: Verify all source files exist**

```bash
SRC=/Users/vladislav/Documents/00_CODE/project_template
for path in CLAUDE.md docs/architecture.md docs/features.md docs/roadmap.md \
            docs-meta/PIPELINE.md docs-meta/LESSON_FORMAT.md \
            .gitignore .claude/settings.json; do
  test -f "$SRC/$path" && echo "source OK: $path" || echo "MISSING: $path"
done
```
Expected: 8 `source OK: ...` lines.

- [ ] **Step 2: Copy with renames**

```bash
SRC=/Users/vladislav/Documents/00_CODE/project_template
DST=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates

cp "$SRC/CLAUDE.md"                    "$DST/CLAUDE.md"
cp "$SRC/docs/architecture.md"         "$DST/architecture.md"
cp "$SRC/docs/features.md"             "$DST/features.md"
cp "$SRC/docs/roadmap.md"              "$DST/roadmap.md"
cp "$SRC/docs-meta/PIPELINE.md"        "$DST/PIPELINE.md"
cp "$SRC/docs-meta/LESSON_FORMAT.md"   "$DST/LESSON_FORMAT.md"
cp "$SRC/.gitignore"                   "$DST/gitignore"           # NOTE: no leading dot
cp "$SRC/.claude/settings.json"        "$DST/settings.json"
```

- [ ] **Step 3: Verify all 8 destination files exist + match source**

```bash
SRC=/Users/vladislav/Documents/00_CODE/project_template
DST=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates

diff -q "$SRC/CLAUDE.md"                  "$DST/CLAUDE.md"        && echo "OK CLAUDE.md"
diff -q "$SRC/docs/architecture.md"       "$DST/architecture.md"  && echo "OK architecture.md"
diff -q "$SRC/docs/features.md"           "$DST/features.md"      && echo "OK features.md"
diff -q "$SRC/docs/roadmap.md"            "$DST/roadmap.md"       && echo "OK roadmap.md"
diff -q "$SRC/docs-meta/PIPELINE.md"      "$DST/PIPELINE.md"      && echo "OK PIPELINE.md"
diff -q "$SRC/docs-meta/LESSON_FORMAT.md" "$DST/LESSON_FORMAT.md" && echo "OK LESSON_FORMAT.md"
diff -q "$SRC/.gitignore"                 "$DST/gitignore"        && echo "OK gitignore (no dot)"
diff -q "$SRC/.claude/settings.json"      "$DST/settings.json"    && echo "OK settings.json"
```
Expected: 8 `OK ...` lines.

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add assets/templates/
git commit -m "feat: migrate 8 per-project template files to assets/templates/

These are the files /init writes into a user's new project cwd:
- CLAUDE.md, architecture.md, features.md, roadmap.md
- PIPELINE.md, LESSON_FORMAT.md
- gitignore (rendered as .gitignore by /init)
- settings.json (rendered into .claude/settings.json)"
```

---

## Task 8: Update `assets/templates/settings.json` to enable `ai-pipeline`

The migrated settings.json doesn't list `ai-pipeline@ai-pipeline-marketplace` in `enabledPlugins` (it predates this plugin). Every project bootstrapped by `/init` should have the plugin auto-enabled.

**Files:**
- Modify: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/settings.json`

- [ ] **Step 1: Inspect current state**

```bash
python3 -c "
import json
s = json.load(open('/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/settings.json'))
print('current enabledPlugins:', list(s['enabledPlugins'].keys()))
print('ai-pipeline already enabled:', 'ai-pipeline@ai-pipeline-marketplace' in s['enabledPlugins'])
"
```
Expected: lists 4 plugins (superpowers, beads, template-bridge, context7-plugin); `ai-pipeline already enabled: False`.

- [ ] **Step 2: Add `ai-pipeline@ai-pipeline-marketplace: true` to enabledPlugins**

Use the Edit tool to insert the new line into the `enabledPlugins` block. The current block looks like:

```json
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "beads@beads-marketplace": true,
    "template-bridge@template-bridge-marketplace": true,
    "context7-plugin@context7-marketplace": true
  }
```

Change to:

```json
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "beads@beads-marketplace": true,
    "template-bridge@template-bridge-marketplace": true,
    "context7-plugin@context7-marketplace": true,
    "ai-pipeline@ai-pipeline-marketplace": true
  }
```

(Add a comma after the previous last entry.)

- [ ] **Step 3: Verify JSON still valid + ai-pipeline now enabled**

```bash
python3 -c "
import json
s = json.load(open('/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/assets/templates/settings.json'))
assert 'ai-pipeline@ai-pipeline-marketplace' in s['enabledPlugins'], 'NOT in enabledPlugins'
assert s['enabledPlugins']['ai-pipeline@ai-pipeline-marketplace'] is True
print('PASS — ai-pipeline enabled in template settings')
"
```
Expected: `PASS — ai-pipeline enabled in template settings`

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add assets/templates/settings.json
git commit -m "feat(templates): enable ai-pipeline plugin in per-project settings.json"
```

---

## Task 9: Rewrite `commands/init.md`

This is the biggest task. The new `/init` command differs from the original (in `project_template/`) in three key ways:

1. **Phase 1 (NEW): Prerequisite scan + auto-install** — detects missing prereq plugins, asks one-line consent, runs `claude plugin install` for each
2. **Phase 3 (NEW): Write template files from `assets/templates/`** — the templates are no longer pre-`cp -r`'d into the cwd
3. **Plugin path resolution** — `/init` must locate its own assets at `~/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/<version>/assets/templates/`

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/init.md`

- [ ] **Step 1: Write the failing test**

```bash
test -f /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/init.md && echo EXISTS || echo MISSING
```
Expected: `MISSING`

- [ ] **Step 2: Write the file**

Content for `commands/init.md`:

````markdown
---
description: Bootstrap a new project. Auto-installs missing prereq plugins, writes the per-project file tree (CLAUDE.md, docs/, docs-meta/, .claude/), runs git init + bd init, makes first commit. Run once per project in an empty folder.
argument-hint: "<one-line app description>"
---

# /init — bootstrap a new project (plugin version)

**Input:** `$ARGUMENTS` (the one-line app description)

This command runs in 7 phases. It is designed to be safe in an empty folder and refuse in a folder that already has source code.

---

## Phase 0: Pre-flight

1. **Refuse if cwd has feature code:**
   ```bash
   ls -A | grep -E "^(package\.json|pyproject\.toml|Cargo\.toml|go\.mod|Gemfile|src|app|lib)$" | head -1
   ```
   If output is non-empty → STOP. Print:
   `Folder has source code already. Use an empty folder for /init, or remove the existing files.`

2. **Refuse if CLAUDE.md already exists at cwd:**
   ```bash
   test -f CLAUDE.md && echo EXISTS
   ```
   If `EXISTS` → STOP. Print:
   `CLAUDE.md already exists. This project may already be initialized. Use /plan-improve to refine, not /init.`

If both checks pass, proceed.

---

## Phase 1: Prerequisite scan + auto-install

The pipeline depends on 4 Claude Code plugins. Detect which are missing and install them.

1. **List installed plugins:**
   ```bash
   claude plugin list 2>&1 | tee /tmp/.ai-pipeline-init-plugins.txt
   ```

2. **Compute MISSING set.** Required plugins:
   - `superpowers` (from `claude-plugins-official` marketplace)
   - `beads` (from `beads-marketplace`)
   - `context7-plugin` (from `context7-marketplace`)
   - `template-bridge` (from `template-bridge-marketplace`)

   For each, check if it appears as enabled in the `claude plugin list` output. If not, add to MISSING.

3. **If MISSING is non-empty:**

   Print one-line preview:
   ```
   About to install missing prerequisite plugins: <comma-separated names>. Proceed? [y/n]
   ```

   Wait for user input (one character).

   - On `y`: for each missing plugin, run `claude plugin install <name>@<marketplace>` (use the correct marketplace name per plugin).
     - If install command fails, print warning: `Could not install <name>: <error>. You may need to add the marketplace first: claude plugin marketplace add github:<owner>/<repo>`
     - Continue regardless of install failures.
   - On `n`: print warning: `Continuing without missing plugins. Some pipeline phases will operate in degraded mode (specifically: brainstorming, beads, lessons context lookup may be limited).` Continue.

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

## Phase 2: Clarify (3 multi-choice questions)

Ask the user **exactly 3 questions** in sequence, one per message. Wait for answers.

1. **What's the primary tech stack?**
   A) Next.js + TypeScript + Postgres
   B) Python (FastAPI/Django/Flask)
   C) Go
   D) Other (let user specify in free text)

2. **Who is the primary user?**
   A) End consumer
   B) Developer / technical user
   C) Internal team
   D) Other (specify)

3. **What's the single most important quality constraint?**
   A) Speed to ship
   B) Security / compliance
   C) Performance
   D) Maintainability

Capture the 3 answers as `STACK_ANSWER`, `USER_ANSWER`, `QUALITY_ANSWER` for use in Phase 4.

---

## Phase 3: Write template files from plugin assets

Resolve the plugin's install location. The expected path is:
```
~/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/<version>/assets/templates/
```

Find the version directory dynamically:

```bash
PLUGIN_BASE="$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline"
TEMPLATE_DIR=""
if [ -d "$PLUGIN_BASE" ]; then
  # Pick the highest semver-looking subdirectory
  TEMPLATE_DIR=$(ls "$PLUGIN_BASE" 2>/dev/null | sort -V | tail -1)
  TEMPLATE_DIR="$PLUGIN_BASE/$TEMPLATE_DIR/assets/templates"
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "ERROR: cannot find ai-pipeline plugin templates at $PLUGIN_BASE"
  echo "Expected: $HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/<version>/assets/templates/"
  echo "Try reinstalling: claude plugin install ai-pipeline@ai-pipeline-marketplace"
  exit 1
fi
```

If the templates directory cannot be found, STOP with the error message above.

Then create cwd subdirectories and copy templates:

```bash
mkdir -p .claude/lessons docs/superpowers/specs docs/superpowers/plans docs/superpowers/critic-reports docs-meta .claude

cp "$TEMPLATE_DIR/CLAUDE.md"          ./CLAUDE.md
cp "$TEMPLATE_DIR/architecture.md"    ./docs/architecture.md
cp "$TEMPLATE_DIR/features.md"        ./docs/features.md
cp "$TEMPLATE_DIR/roadmap.md"         ./docs/roadmap.md
cp "$TEMPLATE_DIR/PIPELINE.md"        ./docs-meta/PIPELINE.md
cp "$TEMPLATE_DIR/LESSON_FORMAT.md"   ./docs-meta/LESSON_FORMAT.md
cp "$TEMPLATE_DIR/gitignore"          ./.gitignore       # rename: no leading dot in source
cp "$TEMPLATE_DIR/settings.json"      ./.claude/settings.json
```

Verify all files copied:
```bash
for f in CLAUDE.md docs/architecture.md docs/features.md docs/roadmap.md \
         docs-meta/PIPELINE.md docs-meta/LESSON_FORMAT.md \
         .gitignore .claude/settings.json; do
  test -f "$f" && echo "  ✓ $f" || echo "  ✗ MISSING: $f"
done
```

If any are missing, STOP — something went wrong with the template copy.

---

## Phase 4: Fill placeholders in Master Plan files

Use the description (`$ARGUMENTS`) and the 3 answers to populate the templates.

1. **`docs/architecture.md`** — replace the `UNFILLED` status sentinel and fill sections 1-6:
   - §1 What this app is — one paragraph derived from `$ARGUMENTS` and `USER_ANSWER`
   - §2 Tech stack — fill the table based on `STACK_ANSWER` (use Context7 to verify version recommendations if available; if not, skip with note)
   - §3 Key modules / boundaries — propose 3-7 modules typical for the chosen stack
   - §4 Data flow — 2-5 sentences
   - §5 External services — list any obvious ones (auth, payments, etc.) or "none yet"
   - §6 Hard architectural constraints — derived from `QUALITY_ANSWER`

2. **`docs/features.md`** — under "Planned", list 5-8 initial features with IDs `F-001` through `F-008`. Each line:
   ```
   - [ ] [F-00N] <slug> — <one-line description> — planned
   ```

3. **`docs/roadmap.md`**:
   - Now: top 3 features from features.md, one-sentence rationale each
   - Next: features 4-6
   - Later: features 7-8
   - Explicitly NOT doing: 1-2 honest entries

Use Context7 if available to ground stack-specific advice:
```
mcp__plugin_context7-plugin_context7__resolve-library-id { libraryName: "<framework>" }
mcp__plugin_context7-plugin_context7__query-docs { id: "<resolved>", topic: "best practices" }
```

If Context7 lookup fails, continue without it.

---

## Phase 5: Initialize beads (conditional)

If `bd` CLI was detected as PRESENT in Phase 1:

```bash
bd init
```

If `bd init` succeeds, create one epic placeholder (use the app's slug derived from `$ARGUMENTS`):

```bash
bd create -t epic "Initial development of <app slug>"
```

If `bd init` fails because already initialized, continue silently.

If `bd` was MISSING, skip this phase silently (Phase 1 already warned).

---

## Phase 6: Initialize git + first commit

```bash
git init
git add -A
git commit -m "chore: scaffold via /init

App: $ARGUMENTS
Stack: <STACK_ANSWER>
Pipeline: ai-pipeline plugin v0.1.0 (6-command AI development pipeline)
Generated by: /init"
```

If `git init` fails because the folder is already a git repo:
- Skip the init
- Still run `git add -A && git commit -m "chore: pipeline scaffold via /init"`

---

## Phase 7: Report + handoff

Print a structured summary:

```
✓ Bootstrap complete.

Wrote:
  - CLAUDE.md, .gitignore
  - docs/architecture.md (filled)
  - docs/features.md (8 planned features)
  - docs/roadmap.md (3-now, 3-next, 2-later)
  - docs-meta/PIPELINE.md, docs-meta/LESSON_FORMAT.md
  - .claude/settings.json (ai-pipeline plugin enabled)
  - .claude/lessons/, docs/superpowers/{specs,plans,critic-reports}/

Initialized:
  - git (first commit: <sha>)
  - beads (epic: <epic-id>)  [or: skipped — bd not installed]

Next steps:
  1. Review docs/architecture.md, docs/features.md, docs/roadmap.md
  2. If anything is wrong: /plan-improve "<change>"
  3. When ready to build: /feature "<first feature description>"
```

---

## Error handling summary

| Failure | Action |
|---|---|
| Folder has source code | Refuse, ask for empty folder |
| CLAUDE.md already exists | Refuse, suggest /plan-improve |
| User declines auto-install | Continue with degraded warning |
| `claude plugin install` fails for a prereq | Continue, warn user |
| `bd` CLI missing | Print install instructions, continue without bd |
| Plugin templates directory not found | STOP — reinstall instructions |
| Context7 lookup fails | Continue without Context7 grounding, note in architecture.md |
| `git init` fails (existing repo) | Skip init, still commit |
| User declines to answer Phase 2 questions | Stop — /init requires all 3 answers |

## Constraints

- /init MUST work in a brand-new empty folder
- /init MUST NOT touch files outside the cwd
- /init MUST NOT install Node modules, Python packages, or any application dependencies
- /init MUST NOT push to any git remote (user pushes manually if desired)
````

- [ ] **Step 3: Verify the file**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/commands/init.md
test -f "$F" && echo "EXISTS"
head -5 "$F" | grep -q "^description:" && echo "frontmatter description OK"
head -5 "$F" | grep -q "^argument-hint:" && echo "frontmatter argument-hint OK"
for phase in "Phase 0:" "Phase 1:" "Phase 2:" "Phase 3:" "Phase 4:" "Phase 5:" "Phase 6:" "Phase 7:"; do
  grep -q "^## $phase" "$F" && echo "  $phase present" || echo "  ✗ MISSING $phase"
done
grep -q "claude plugin install" "$F" && echo "auto-install present"
grep -q "About to install missing" "$F" && echo "consent prompt present"
grep -q "ai-pipeline-marketplace/ai-pipeline" "$F" && echo "plugin path resolution present"
grep -q "TEMPLATE_DIR" "$F" && echo "TEMPLATE_DIR variable used"
grep -q "exactly 3 questions" "$F" && echo "3-question constraint stated"
grep -q "ai-pipeline plugin v0.1.0" "$F" && echo "version mentioned in commit message"
```
Expected: 14 confirmation lines (EXISTS + 2 frontmatter + 8 phases + auto-install + consent + path + TEMPLATE_DIR + 3-question + version).

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add commands/init.md
git commit -m "feat(/init): rewrite for plugin context

- Phase 1: auto-install missing prereq plugins with one-line consent
- Phase 3: resolve plugin install path and copy templates from assets/templates/
- Phases 2/4-7 unchanged from project_template version
- Refuses if cwd has source code or CLAUDE.md already exists"
```

---

## Task 10: Write `README.md` (English)

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/README.md`

- [ ] **Step 1: Write the file**

Content:

````markdown
# ai-pipeline

A Claude Code plugin that ships a 6-command AI development pipeline with an automatic senior-engineer critic at two gates and a lessons-learned flywheel.

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

You never type `/brainstorm`, `/plan`, `/build`, `/critic`, `/verify`, or `/finish` — those are internal phases of the 6 commands above.

## Install

```bash
claude plugin marketplace add github:easyhex/ai-pipeline-plugin
claude plugin install ai-pipeline@ai-pipeline-marketplace
```

That's it. The 6 commands and the `senior-critic` agent are now available globally in any project.

## Bootstrap a new project

```bash
mkdir my-new-app
cd my-new-app
claude
> /init "todo app with realtime sync"
```

`/init` will:
1. Auto-install any missing prerequisite plugins (with a one-line `[y/n]` preview)
2. Ask 3 multi-choice questions (stack / user / quality constraint)
3. Write the per-project file tree (CLAUDE.md, docs/, docs-meta/, .claude/)
4. Fill the 3 Master Plan files (architecture, features, roadmap) with concrete content
5. Run `git init` and `bd init` (if `bd` is installed)
6. Make the first commit

After `/init` completes, you start building features:

```
> /feature "add user signup with magic link auth"
```

The pipeline runs end-to-end automatically — ground (read codebase + lessons + Context7), brainstorm spec, critic gate-1, plan, beads tasks, TDD loop with auto-commits, critic gate-2, verify, merge or PR — only stopping when the brainstorm has a real clarifying question or the critic surfaces a Critical finding.

## Prerequisites

The plugin depends on 4 other Claude Code plugins. `/init` auto-installs any that are missing (with consent):

- **superpowers** — TDD, brainstorming, debugging, verification, code review
- **beads** — persistent task tracking across sessions
- **context7-plugin** — live library documentation via MCP
- **template-bridge** — 413+ specialist agent templates

Plus one CLI tool that must be installed manually:

- **`bd`** (Beads CLI): `brew install beads` (macOS) or `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash`

## Architecture

The pipeline has three layers:

1. **6 user-facing commands** (in `commands/`) — auto-loaded by Claude Code
2. **`senior-critic` subagent** (in `agents/`) — auto-loaded, invoked at two gates per feature
3. **Per-project templates** (in `assets/templates/`) — written into your project by `/init`

Per-project files written by `/init`:

- `CLAUDE.md` — pipeline rules and the 6-command surface
- `docs/architecture.md` — Master Plan: target architecture (≤300 lines)
- `docs/features.md` — Master Plan: feature inventory (≤500 lines)
- `docs/roadmap.md` — Master Plan: ordered priorities (≤200 lines)
- `docs-meta/PIPELINE.md` — pipeline reference doc
- `docs-meta/LESSON_FORMAT.md` — lesson schema (4 YAML fields + 3-sentence body)
- `.claude/settings.json` — hooks + enabled plugins (including `ai-pipeline`)
- `.gitignore` — common ignores
- `.claude/lessons/` — populated over time by `/fix` and `/lesson`

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

## Contributing

See `CLAUDE.md` for plugin contributor rules. Templates in `assets/templates/` are user-facing — keep them consistent with the per-project `CLAUDE.md` they ship.

## License

MIT — see [LICENSE](LICENSE).
````

- [ ] **Step 2: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/README.md
test -f "$F" && echo EXISTS
grep -q "^# ai-pipeline" "$F" && echo "title OK"
for cmd in init plan-improve feature improve fix lesson; do
  grep -q "/$cmd" "$F" && echo "documents: /$cmd"
done
grep -q "claude plugin install ai-pipeline@ai-pipeline-marketplace" "$F" && echo "install command present"
grep -q "Prerequisites" "$F" && echo "prereq section present"
grep -q "MIT" "$F" && echo "license mentioned"
```
Expected: EXISTS + title + 6 commands + install + prereq + license.

- [ ] **Step 3: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add README.md
git commit -m "docs: add English README"
```

---

## Task 11: Write `README_RU.md` + migrate `WORKFLOW_GUIDE_RU.md`

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/README_RU.md`
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs/WORKFLOW_GUIDE_RU.md` (migrated from `project_template/CLAUDE_CODE_WORKFLOW_GUIDE_RU.md`)

- [ ] **Step 1: Migrate the workflow guide**

```bash
cp /Users/vladislav/Documents/00_CODE/project_template/CLAUDE_CODE_WORKFLOW_GUIDE_RU.md \
   /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs/WORKFLOW_GUIDE_RU.md
```

Verify:
```bash
diff -q /Users/vladislav/Documents/00_CODE/project_template/CLAUDE_CODE_WORKFLOW_GUIDE_RU.md \
        /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs/WORKFLOW_GUIDE_RU.md \
  && echo "identical"
```
Expected: `identical`

- [ ] **Step 2: Write `README_RU.md`**

Content (Russian translation mirroring README.md structure):

````markdown
# ai-pipeline

Плагин для Claude Code — пайплайн AI-разработки из 6 команд с автоматическим критиком (senior engineer) на двух стадиях и системой накопления уроков.

## Что вы получаете

После установки плагина вы можете создать любой новый проект одной командой и вести каждую фичу от начала до конца через крошечный набор слэш-команд:

| Команда | Когда |
|---|---|
| `/init "<описание>"` | Один раз при старте проекта |
| `/plan-improve "<изменение>"` | Уточнить мастер-план (без кода) |
| `/feature "<описание>"` | Новая функциональность — полный автоматический пайплайн |
| `/improve "<изменение>"` | Изменение существующего поведения — полный пайплайн |
| `/fix "<баг>"` | Отладка + автозапись урока |
| `/lesson` | Записать урок вручную (редко) |

Вы никогда не вводите `/brainstorm`, `/plan`, `/build`, `/critic`, `/verify` или `/finish` — это внутренние фазы шести команд выше.

## Установка

```bash
claude plugin marketplace add github:easyhex/ai-pipeline-plugin
claude plugin install ai-pipeline@ai-pipeline-marketplace
```

Всё. 6 команд и агент `senior-critic` теперь доступны глобально в любом проекте.

## Создание нового проекта

```bash
mkdir my-new-app
cd my-new-app
claude
> /init "todo-приложение с realtime синхронизацией"
```

`/init` выполнит:
1. Автоустановку отсутствующих плагинов-зависимостей (с подтверждением `[y/n]`)
2. 3 вопроса с вариантами ответа (стек / пользователь / приоритет)
3. Запись файлов проекта (CLAUDE.md, docs/, docs-meta/, .claude/)
4. Заполнение 3 файлов мастер-плана (архитектура, фичи, roadmap)
5. `git init` и `bd init` (если `bd` установлен)
6. Первый коммит

После `/init` вы начинаете писать фичи:

```
> /feature "добавить регистрацию пользователей через magic link"
```

Пайплайн работает полностью автоматически — ground (чтение кодовой базы + уроки + Context7), brainstorm спецификации, критик gate-1, план, beads-задачи, TDD-цикл с автокоммитами, критик gate-2, верификация, merge или PR — останавливается только если brainstorm требует уточнения или критик находит Critical-проблему.

## Зависимости

Плагин зависит от 4 других плагинов Claude Code. `/init` автоматически установит отсутствующие (с согласия):

- **superpowers** — TDD, brainstorming, отладка, верификация, code review
- **beads** — постоянное отслеживание задач между сессиями
- **context7-plugin** — актуальная документация библиотек через MCP
- **template-bridge** — 413+ специализированных агентов

Плюс один CLI-инструмент, который надо ставить вручную:

- **`bd`** (Beads CLI): `brew install beads` (macOS) или `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash`

## Архитектура

Пайплайн состоит из трёх слоёв:

1. **6 пользовательских команд** (в `commands/`) — загружаются Claude Code автоматически
2. **Агент `senior-critic`** (в `agents/`) — загружается автоматически, вызывается на двух стадиях каждой фичи
3. **Шаблоны проекта** (в `assets/templates/`) — записываются в проект командой `/init`

Файлы проекта, которые пишет `/init`:

- `CLAUDE.md` — правила пайплайна и набор из 6 команд
- `docs/architecture.md` — мастер-план: целевая архитектура (≤300 строк)
- `docs/features.md` — мастер-план: список фич (≤500 строк)
- `docs/roadmap.md` — мастер-план: упорядоченные приоритеты (≤200 строк)
- `docs-meta/PIPELINE.md` — справочник по пайплайну
- `docs-meta/LESSON_FORMAT.md` — схема урока (4 YAML-поля + 3 предложения тела)
- `.claude/settings.json` — хуки + включённые плагины (включая `ai-pipeline`)
- `.gitignore` — стандартные исключения
- `.claude/lessons/` — наполняется со временем командами `/fix` и `/lesson`

Полное описание дизайна — см. `docs/DESIGN_NOTES.md` и `docs/WORKFLOW_GUIDE_RU.md`.

## Обновление плагина

```bash
claude plugin install ai-pipeline@ai-pipeline-marketplace
```

Это перезатягивает плагин из источника. Существующие проекты продолжают работать — у них есть своя копия шаблонов с момента `/init`.

## Жёсткие правила (per-project CLAUDE.md)

После `/init` файл `CLAUDE.md` в проекте требует:

1. Никакого production-кода без падающего теста сначала
2. Никаких "готово" без запуска проверочной команды
3. Уроки применяются автоматически перед каждой фазой
4. Context7-запрос перед использованием любой библиотеки/фреймворка
5. Критик на gate-1 (после спеки) и gate-2 (после диффа)
6. Каждый зелёный TDD-цикл заканчивается `git commit`; каждый `/fix` пишет урок

## Контрибуция

См. `CLAUDE.md` — правила для контрибьюторов плагина. Шаблоны в `assets/templates/` — это user-facing файлы; держите их в соответствии с тем `CLAUDE.md`, который они доставляют пользователям.

## Лицензия

MIT — см. [LICENSE](LICENSE).
````

- [ ] **Step 3: Verify**

```bash
F1=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/README_RU.md
F2=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs/WORKFLOW_GUIDE_RU.md
test -f "$F1" && echo "README_RU.md EXISTS"
test -f "$F2" && echo "WORKFLOW_GUIDE_RU.md EXISTS"
grep -q "^# ai-pipeline" "$F1" && echo "RU README title OK"
for cmd in init plan-improve feature improve fix lesson; do
  grep -q "/$cmd" "$F1" && echo "RU README documents: /$cmd"
done
grep -q "MIT" "$F1" && echo "RU license mentioned"
```
Expected: 2 EXISTS + RU title + 6 commands + license.

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add README_RU.md docs/WORKFLOW_GUIDE_RU.md
git commit -m "docs: add Russian README and migrate WORKFLOW_GUIDE_RU"
```

---

## Task 12: Write plugin contributor `CLAUDE.md`

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/CLAUDE.md`

This is the plugin REPO's own CLAUDE.md (rules for contributors), distinct from `assets/templates/CLAUDE.md` (which ships to user projects).

- [ ] **Step 1: Write the file**

Content:

```markdown
# Contributor rules — ai-pipeline plugin

This file applies to anyone (human or AI agent) editing this **plugin repo**. It is NOT the per-project CLAUDE.md that ships to users — that one lives at `assets/templates/CLAUDE.md`.

## Before any change

1. Understand the layered structure:
   - `commands/` — 6 slash commands, auto-loaded
   - `agents/` — `senior-critic` subagent, auto-loaded
   - `assets/templates/` — files `/init` writes into user projects (do not auto-load)
   - `.claude-plugin/` — plugin manifest + marketplace entry
2. Templates in `assets/templates/` are user-facing. Changes to them ship to every new project after the next plugin update.

## Hard rules for plugin changes

1. **Templates and the per-project CLAUDE.md must stay consistent.** If you change `assets/templates/CLAUDE.md`'s rules, also check `assets/templates/PIPELINE.md` and the command files in `commands/` for drift.
2. **Lesson schema is canonical.** `assets/templates/LESSON_FORMAT.md` defines the schema. Any reference to lesson fields elsewhere (in `commands/` or `agents/senior-critic.md`) must match. Body length is a 3-sentence hard limit.
3. **Bumping the version**: any change to command behavior or template content requires a version bump in `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json`. Use semver (MAJOR.MINOR.PATCH).
4. **Test before publishing**: every change must be smoke-tested by running `/init` in `/tmp/test-<n>/` and confirming all per-project files are written correctly.
5. **Two READMEs**: `README.md` (English) and `README_RU.md` (Russian) must be updated together.
6. **No git push from inside Claude.** User pushes manually.

## Smoke test workflow

```bash
# Local install (for testing before publishing)
claude plugin marketplace add /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin

# In a fresh terminal:
mkdir /tmp/ai-pipeline-smoke-$$
cd /tmp/ai-pipeline-smoke-$$
claude
> /init "test app"
# Verify:
> /help            # confirm 6 commands appear
> ls               # confirm CLAUDE.md, docs/, docs-meta/, .claude/, .gitignore present
```

After smoke test, clean up:
```bash
rm -rf /tmp/ai-pipeline-smoke-*
```

## Versioning policy

- 0.x → breaking changes between minor versions are OK
- 1.x → semver enforced (breaking changes only on major)
- Tag every release: `git tag v<version> && git push origin v<version>`

## What this plugin does NOT do

- Cross-agent compatibility (Claude Code only)
- Auto-install of system tools (`bd`, `gh`, `node`)
- Language-specific scaffolding (no `package.json` writing)
- Auto-push to remotes
```

- [ ] **Step 2: Verify**

```bash
F=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/CLAUDE.md
test -f "$F" && echo EXISTS
grep -q "Contributor rules" "$F" && echo "title OK"
grep -q "assets/templates/CLAUDE.md" "$F" && echo "distinguishes from per-project CLAUDE.md"
grep -q "Bumping the version" "$F" && echo "version policy present"
grep -q "Smoke test" "$F" && echo "smoke test instructions present"
```
Expected: EXISTS + 4 confirmations.

- [ ] **Step 3: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add CLAUDE.md
git commit -m "docs: add plugin contributor CLAUDE.md"
```

---

## Task 13: Write `docs/DESIGN_NOTES.md` and `settings.example.json`

**Files:**
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs/DESIGN_NOTES.md`
- Create: `/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/settings.example.json`

- [ ] **Step 1: Write `docs/DESIGN_NOTES.md`**

Content:

```markdown
# Design notes

This plugin packages a 6-command AI development pipeline. The full design rationale is captured in two specs that live in the predecessor repo (the original `project_template/` directory used to develop this plugin):

- **Pipeline design** — the 6 commands, the `senior-critic` agent, the lessons system, the Master Plan split: see the original spec at `project_template/docs/superpowers/specs/2026-04-25-ai-pipeline-design.md`
- **Plugin packaging design** — turning the per-project pipeline into an installable Claude Code plugin: see `project_template/docs/superpowers/specs/2026-04-25-ai-pipeline-plugin-design.md`

## Why this design

**Why 6 commands and not more?**
Each user-facing command corresponds to one cognitive operation: bootstrap, refine plan, build new, modify existing, debug, capture lesson. Internal phases (brainstorm, plan, TDD, critic, verify, finish) are not commands because the user shouldn't have to orchestrate them — that's the pipeline's job.

**Why a critic at two gates?**
Gate-1 (post-spec) catches design holes before any code is written. Gate-2 (post-diff) catches implementation drift. The critic is a senior reviewer that produces findings, not approvals — the user decides what to address.

**Why a lessons system?**
Without a feedback loop, the pipeline learns nothing across runs. `/fix` writes a lesson at the end of every debug; `senior-critic` reads them at every gate. Over weeks, the system stops repeating mistakes.

**Why Lean `/init`?**
Scaffolding a Next.js or Python skeleton is a separate, opinionated project. Most teams already have a preferred starter. The pipeline's value is the process discipline, not the file tree.

## What's not here

- **No cross-agent support.** Claude Code only. If we ever ported, we'd build a parallel npm CLI (the AI Factory model).
- **No auto-system-install.** `bd` CLI requires brew or curl; we document, we don't run.
- **No telemetry.** Lessons stay local; nothing leaves your machine.
```

- [ ] **Step 2: Write `settings.example.json`**

This is an OPTIONAL global hooks block users may merge into their `~/.claude/settings.json`. Most users will rely on the per-project `.claude/settings.json` written by `/init` — this file exists for the rare user who wants global hooks.

Content:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bd prime 2>/dev/null || true" },
          { "type": "command", "command": "echo 'WORKFLOW: ai-pipeline plugin loaded. Run /init to bootstrap, /feature to build.'" }
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
  }
}
```

- [ ] **Step 3: Verify**

```bash
F1=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/docs/DESIGN_NOTES.md
F2=/Users/vladislav/Documents/00_CODE/ai-pipeline-plugin/settings.example.json
test -f "$F1" && echo "DESIGN_NOTES.md EXISTS"
test -f "$F2" && echo "settings.example.json EXISTS"
python3 -c "import json; json.load(open('$F2')); print('settings.example.json: valid JSON')"
grep -q "Why 6 commands" "$F1" && echo "design notes content OK"
```
Expected: 4 confirmations.

- [ ] **Step 4: Commit**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git add docs/DESIGN_NOTES.md settings.example.json
git commit -m "docs: add design notes and example global settings"
```

---

## Task 14: Local install + smoke test

**Files:** none created — this task verifies the plugin works locally before publishing.

- [ ] **Step 1: Add the plugin's local path as a marketplace**

```bash
claude plugin marketplace add /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
```

Expected output: confirmation that the marketplace was added. If error, capture the full output and STOP — investigate before continuing.

- [ ] **Step 2: Install the plugin**

```bash
claude plugin install ai-pipeline@ai-pipeline-marketplace
```

Expected: install success message.

- [ ] **Step 3: Verify plugin is discovered**

```bash
claude plugin list 2>&1 | grep -i "ai-pipeline" && echo "plugin discovered"
```
Expected: line includes `ai-pipeline` and the marketplace name.

- [ ] **Step 4: Verify the cache directory exists with assets**

```bash
ls "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/"
echo "---"
ls "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/0.1.0/assets/templates/" 2>&1 | head -10
```
Expected: version directory `0.1.0/`, and templates directory contains all 8 asset files.

- [ ] **Step 5: Verify commands are loadable**

This requires opening Claude Code in a separate session — automated check is tricky. Manual step:

```bash
# In a separate terminal:
mkdir /tmp/ai-pipeline-smoke-$$
cd /tmp/ai-pipeline-smoke-$$
claude
# Inside Claude Code:
> /help
# Confirm /init, /plan-improve, /feature, /improve, /fix, /lesson all appear in the slash command list.
# DO NOT run /init yet — that's Task 15.
# Type Ctrl-D or /exit to leave.
```

Note this is a manual check — the implementer should pause here and ask the user to run it and confirm.

- [ ] **Step 6: Commit (no file changes — but record the test in repo)**

This task changes no files in the plugin repo. Skip commit.

---

## Task 15: End-to-end `/init` test

**Files:** none created in plugin repo — this task verifies `/init` works in a fresh project.

This is also a partly-manual task: the implementer instructs the user to run `/init` in a fresh terminal and reports the results.

- [ ] **Step 1: Create a fresh test directory**

```bash
TEST_DIR=/tmp/ai-pipeline-init-test-$$
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
echo "Test directory: $TEST_DIR"
```

- [ ] **Step 2: Open Claude Code and run `/init`**

User instruction (manual step):

```
In the same terminal:
  claude

Inside Claude Code, run:
  /init "todo app with realtime sync"

Answer the 3 multi-choice questions interactively.
Approve the auto-install prompt if any plugins are missing.
Wait for the bootstrap to complete.
Type /exit when /init reports done.
```

- [ ] **Step 3: Verify the produced file tree**

After the user exits Claude Code, run:

```bash
TEST_DIR=<the test directory from Step 1>
cd "$TEST_DIR"

echo "=== File presence ==="
for f in CLAUDE.md .gitignore docs/architecture.md docs/features.md docs/roadmap.md \
         docs-meta/PIPELINE.md docs-meta/LESSON_FORMAT.md .claude/settings.json; do
  test -f "$f" && echo "  ✓ $f" || echo "  ✗ MISSING: $f"
done

echo "=== Master Plan filled (not UNFILLED) ==="
grep -q "^**Status:** UNFILLED" docs/architecture.md && echo "  ✗ architecture.md still UNFILLED" || echo "  ✓ architecture.md filled"

echo "=== Settings has ai-pipeline enabled ==="
python3 -c "
import json
s = json.load(open('.claude/settings.json'))
assert 'ai-pipeline@ai-pipeline-marketplace' in s['enabledPlugins']
print('  ✓ ai-pipeline enabled in per-project settings')
"

echo "=== Git initialized + first commit ==="
git log --oneline | head -3 && echo "  ✓ git history present"

echo "=== Beads epic exists (if bd installed) ==="
command -v bd >/dev/null && bd list --type epic 2>&1 | head -3 || echo "  bd not installed — skipped"
```
Expected: all `✓` lines, no `✗` lines.

- [ ] **Step 4: Cleanup**

```bash
TEST_DIR=<the test directory>
rm -rf "$TEST_DIR"
echo "  ✓ cleaned up"
```

- [ ] **Step 5: Commit (no plugin repo changes)**

This task changes no files in the plugin repo. Skip commit.

---

## Task 16: Push to GitHub

**Files:** none created — this task publishes the plugin to GitHub.

- [ ] **Step 1: Verify GitHub repo exists**

The repo URL is `https://github.com/easyhex/ai-pipeline-plugin`. Check:

```bash
gh repo view easyhex/ai-pipeline-plugin 2>&1 | head -3
```

Expected: shows the repo metadata. If it returns an error like `Could not resolve to a Repository`, the user must create the repo first:

```bash
# If repo doesn't exist, the user runs (manually, not the agent):
gh repo create easyhex/ai-pipeline-plugin --public --description "6-command AI dev pipeline as Claude Code plugin"
```

The agent should STOP and ask the user to create the repo if it doesn't exist.

- [ ] **Step 2: Add the remote**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git remote add origin https://github.com/easyhex/ai-pipeline-plugin.git
git remote -v
```

Expected: `origin  https://github.com/easyhex/ai-pipeline-plugin.git (fetch)` and (push).

- [ ] **Step 3: Confirm before pushing**

This is a destructive remote action — the agent must explicitly confirm with the user before running `git push`. Print:

```
About to push the local plugin repo to https://github.com/easyhex/ai-pipeline-plugin.
This will create the initial commit history on the remote.
Proceed? [y/n]
```

Wait for `y` from the user.

- [ ] **Step 4: Push**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git push -u origin main 2>&1 | tail -5
```

(If the local branch is `master`, use `master`. Check with `git branch --show-current`.)

Expected: push succeeds. If auth error, ask user to handle (gh CLI auth, SSH key, etc.).

- [ ] **Step 5: Tag the version**

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git tag -a v0.1.0 -m "Release 0.1.0 — initial release of ai-pipeline plugin"
git push origin v0.1.0
```

Expected: tag pushed.

- [ ] **Step 6: Verify on GitHub**

```bash
gh repo view easyhex/ai-pipeline-plugin --web
# (opens in browser; or skip --web for terminal output)
```

User confirms the repo is visible with all files and the v0.1.0 tag.

---

## Task 17: Verify install from GitHub

**Files:** none created — this task verifies remote install works for the plugin.

- [ ] **Step 1: Remove the local marketplace entry**

```bash
claude plugin marketplace remove ai-pipeline-marketplace 2>&1 | head -3
```

(If the command name differs, use `claude plugin marketplace --help` to find the right one.)

- [ ] **Step 2: Add the GitHub marketplace entry**

```bash
claude plugin marketplace add github:easyhex/ai-pipeline-plugin
```

Expected: success.

- [ ] **Step 3: Reinstall the plugin from GitHub**

```bash
claude plugin install ai-pipeline@ai-pipeline-marketplace
```

Expected: success.

- [ ] **Step 4: Verify cache contains the GitHub version**

```bash
ls "$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline/0.1.0/assets/templates/" 2>&1 | head -10
```
Expected: 8 template files present.

- [ ] **Step 5: Smoke test `/init` from the GitHub-installed version**

Same as Task 15 — manual user step. Confirm `/init` still works.

- [ ] **Step 6: Final commit (no plugin repo changes)**

Skip — no file changes to commit. Implementation is complete.

---

## Self-review checklist (run by the implementing agent)

After completing all 17 tasks:

1. **Spec coverage:**
   - §3 Architecture (repo layout): Tasks 1-13 produce all 16+ files ✓
   - §4 Install flow: Tasks 14, 17 verify ✓
   - §5 `/init` rewritten: Task 9 ✓
   - §6 Other commands verbatim: Tasks 5, 6 ✓
   - §7 Per-project file mapping: Task 7 ✓
   - §8 plugin.json: Task 2 ✓
   - §9 marketplace.json: Task 3 ✓
   - §10 Documentation: Tasks 10, 11, 12, 13 ✓
   - §11 Migration from project_template: Tasks 5, 6, 7, 11 ✓
   - §12 Acceptance criteria: Tasks 14, 15, 17 ✓
   - §13 Risks: addressed up-front by inline schema verification before plan ✓
   - §14 Out of scope: respected throughout (no cross-agent code, no language scaffolding) ✓

2. **Placeholder scan:** every task has complete content. No "TBD" or "fill in later".

3. **Type/name consistency:**
   - Plugin name `ai-pipeline` consistent across plugin.json, marketplace.json, README, settings template ✓
   - Marketplace name `ai-pipeline-marketplace` consistent ✓
   - Version `0.1.0` consistent across plugin.json, marketplace.json, init.md commit message, README ✓
   - GitHub owner `easyhex` consistent across plugin.json, marketplace.json, README, LICENSE ✓
   - Lesson schema (3-sentence body limit) respected (templates were already fixed in B1 of the prior project) ✓

---

## Post-implementation handoff (for the user)

After all 17 tasks complete, present:

```
✓ Plugin published.

Repo:    https://github.com/easyhex/ai-pipeline-plugin
Version: 0.1.0
Tag:     v0.1.0

Anyone (including you in any new project) can now install with:
  claude plugin marketplace add github:easyhex/ai-pipeline-plugin
  claude plugin install ai-pipeline@ai-pipeline-marketplace

Then bootstrap:
  mkdir my-app && cd my-app && claude
  > /init "<one-line app description>"

The original project_template/ directory is no longer required and can be deleted manually:
  rm -rf /Users/vladislav/Documents/00_CODE/project_template
(Recommend keeping it for ~1 week as a fallback while you confirm the plugin works in real projects.)
```
