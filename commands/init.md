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
