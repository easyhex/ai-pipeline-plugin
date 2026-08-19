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

   Print multi-line preview:
   ```
   About to install missing prerequisites:
     - <missing plugin 1>
     - <missing plugin 2>
     - ...
     - serena-agent (Python tool via uv) + MCP registration   [if uv present and Serena missing]
   Proceed? [y/n]
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

     # Initialize global Serena config (idempotent)
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

6. **Detect Playwright MCP (separate from plugins):**

   The visual-verification gate in Phase 9 of `/feature`, `/improve`, `/fix` requires Playwright MCP for frontend projects.

   ```bash
   command -v npx >/dev/null 2>&1 && echo NPX_PRESENT || echo NPX_MISSING
   ```

   If `NPX_PRESENT`:
   - Detect Playwright MCP registration: `claude mcp list 2>/dev/null | grep -q "^playwright:" && echo PW_MCP_REGISTERED || echo PW_MCP_NOT_REGISTERED`
   - If `PW_MCP_NOT_REGISTERED`, add this line to the consent prompt list (alongside the missing plugins / Serena):
     ```
     - Playwright MCP (browser driver for visual-verify gate; requires npx)
     ```
   - On consent (`y`):
     ```bash
     # Register MCP server at user scope (idempotent — skip if already registered)
     if ! claude mcp list 2>/dev/null | grep -q "^playwright:"; then
       claude mcp add --scope user playwright -- npx '@playwright/mcp@0.0.79' 2>&1 | tail -3
     fi
     ```
   - On any failure: print warning with the exact failed command, continue.

   If `NPX_MISSING`, print:
   ```
   npx not found (Node.js missing). Install Node 18+ to enable visual-verify gate.
   Then re-enable in this project:
     claude mcp add --scope user playwright -- npx '@playwright/mcp@0.0.79'
   Continuing without Playwright MCP — visual-verify gate will be skipped for frontend projects.
   ```

---

## Phase 2: Interview (frontier rounds)

Resolve the plugin templates directory now (same procedure as Phase 3) and read `ELICITATION.md` from it. Run the interview per that file: numbered ❓ questions with ➡️ recommended answers, whole frontier per round, answers by number; facts you can infer or look up are never questions; confirm each substantive answer with a one-sentence paraphrase.

**Round 1 (always):**
- ❓ Stakes: hobby / internal tool / production launch — with a ➡️ recommendation inferred from `$ARGUMENTS`. Maps to the default ceremony weight (hobby→`light`, internal→`standard`, launch→`deep`); Phase 3 writes it into `.claude/settings.json` → `pipeline.default_weight`, and `/feature`'s weight question recommends it.
- ❓ Project class: numerical-library / simulation / data-pipeline / service / ui-app / cli — ➡️ recommend from `$ARGUMENTS`. Written to `.claude/settings.json` → `pipeline.project_class`; sets gate defaults (compute classes and `cli`: `visual_verify.mode: skip`; compute classes: quant gate required; ui-app: visual required) and the coverage-tree variant recommendation (compute → numerics, else generic; see `ELICITATION_TREES.md`).
- ❓ Primary user of the app (who, and what they do with it).
- ❓ Tech stack — recommend one from `$ARGUMENTS` context; free-text welcome (a math-heavy system may be NumPy/SciPy/JAX, Fortran-interop, GPU — never force a web framework).

**Round 2 (recomputed from round 1):**
- ❓ Top 2-3 usage scenarios, in the user's words.
- ❓ Quality forced-ranking: rank what matters most — correctness/precision, performance, reproducibility, security/compliance, speed to ship, maintainability. (Correctness and reproducibility are ALWAYS offered as options.)
- ❓ Negative scope: what this app is explicitly NOT — in the user's words, not invented.

**Round 3 (forced NFR round — never skip):**
- Iterate non-functional dimensions explicitly: precision/tolerance targets (with units, and against what oracle), data scale, performance/memory envelopes, determinism/reproducibility needs, compliance constraints. "Not applicable" is an acceptable answer; not asking is not.

Capture all confirmed answers for Phase 4. Anything the user leaves open becomes a `TBC:` marker in the drafted docs — never silently decided.

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
mkdir -p .claude/lessons docs/superpowers/specs docs/superpowers/plans docs/superpowers/critic-reports docs/superpowers/elicitation docs/requirements docs/decisions docs/analysis docs-meta .claude

cp "$TEMPLATE_DIR/CLAUDE.md"          ./CLAUDE.md
cp "$TEMPLATE_DIR/architecture.md"    ./docs/architecture.md
cp "$TEMPLATE_DIR/features.md"        ./docs/features.md
cp "$TEMPLATE_DIR/roadmap.md"         ./docs/roadmap.md
cp "$TEMPLATE_DIR/PIPELINE.md"        ./docs-meta/PIPELINE.md
cp "$TEMPLATE_DIR/LESSON_FORMAT.md"   ./docs-meta/LESSON_FORMAT.md
cp "$TEMPLATE_DIR/ELICITATION.md"        ./docs-meta/ELICITATION.md
cp "$TEMPLATE_DIR/ELICITATION_TREES.md"  ./docs-meta/ELICITATION_TREES.md
cp "$TEMPLATE_DIR/SPEC_FORMAT.md"        ./docs-meta/SPEC_FORMAT.md
cp "$TEMPLATE_DIR/NUMERICS_TESTING.md"   ./docs-meta/NUMERICS_TESTING.md
cp "$TEMPLATE_DIR/REQUIREMENTS_FORMAT.md" ./docs-meta/REQUIREMENTS_FORMAT.md
cp "$TEMPLATE_DIR/ADR_FORMAT.md"         ./docs-meta/ADR_FORMAT.md
cp "$TEMPLATE_DIR/risks.md"              ./docs/risks.md
cp "$TEMPLATE_DIR/glossary.md"           ./docs/glossary.md
cp "$TEMPLATE_DIR/analogs.md"            ./docs/analysis/analogs.md
cp "$TEMPLATE_DIR/out-of-scope.md"       ./docs/analysis/out-of-scope.md
cp "$TEMPLATE_DIR/gitignore"          ./.gitignore       # rename: no leading dot in source
cp "$TEMPLATE_DIR/settings.json"      ./.claude/settings.json
```

Write the interview's stakes + class answers into settings (defaults: `standard`, `unset`):

```bash
# WEIGHT: light|standard|deep (Round 1 stakes); PCLASS: numerical-library|simulation|data-pipeline|service|ui-app|cli
jq --arg w "$WEIGHT" --arg c "$PCLASS" \
  '.pipeline.default_weight = $w | .pipeline.project_class = $c
   | (if ($c | IN("numerical-library","simulation","data-pipeline","cli")) then .pipeline.visual_verify.mode = "skip" else . end)' \
  .claude/settings.json > /tmp/s.json && mv /tmp/s.json .claude/settings.json
```

For compute classes (numerical-library / simulation / data-pipeline), additionally copy the mathematical-model template:

```bash
cp "$TEMPLATE_DIR/model.md" ./docs/model.md
```

Verify all files copied:
```bash
for f in CLAUDE.md docs/architecture.md docs/features.md docs/roadmap.md \
         docs/risks.md docs/glossary.md docs/analysis/analogs.md docs/analysis/out-of-scope.md \
         docs-meta/PIPELINE.md docs-meta/LESSON_FORMAT.md docs-meta/ELICITATION.md docs-meta/ELICITATION_TREES.md \
         docs-meta/SPEC_FORMAT.md docs-meta/REQUIREMENTS_FORMAT.md docs-meta/ADR_FORMAT.md \
         .gitignore .claude/settings.json; do
  test -f "$f" && echo "  ✓ $f" || echo "  ✗ MISSING: $f"
done
```

If any are missing, STOP — something went wrong with the template copy.

---

## Phase 4: Fill placeholders in Master Plan files

Use the description (`$ARGUMENTS`) and the confirmed interview answers to populate the templates. Prose in the conversation's language; IDs, statuses, and markers always English (see `docs-meta/ELICITATION.md`).

1. **`docs/architecture.md`** — replace the `UNFILLED` status sentinel and fill sections 1-6:
   - §1 What this app is — one paragraph derived from `$ARGUMENTS` and the confirmed primary-user + scenario answers
   - §2 Tech stack — fill the table from the confirmed stack answer (use Context7 to verify version recommendations if available; if not, skip with note)
   - §3 Key modules / boundaries — propose 3-7 modules typical for the chosen stack
   - §4 Data flow — 2-5 sentences
   - §5 External services — list any obvious ones (auth, payments, etc.) or "none yet"
   - §6 Hard architectural constraints — from the quality forced-ranking and the forced NFR round: write the MEASURABLE ones (tolerances with units, performance/memory envelopes, determinism requirements). Anything the user left open → a `TBC:` marker, never an invented constraint

2. **`docs/features.md`** — under "Planned", list 5-8 initial features with IDs `F-001` through `F-008`. Each line:
   ```
   - [ ] [F-00N] <slug> — <one-line description> — planned
   ```

3. **`docs/roadmap.md`**:
   - Now: top 3 features from features.md, one-sentence rationale each
   - Next: features 4-6
   - Later: features 7-8
   - Explicitly NOT doing: entries from the user's OWN negative-scope answers (Round 2); machine-added entries carry `(proposed — unconfirmed)`

4. **`docs/glossary.md`** — seed one row per domain term/symbol the interview surfaced (with units where numeric). Empty is acceptable only if the interview surfaced none.

4b. **`docs/model.md`** (compute classes only) — fill §1-6 from the interview's NFR round: problem statement, assumptions, invariants (these seed the property oracles), units, accuracy targets with their oracles, known failure regimes. Open items become `TBC:` markers.

5. **`docs/analysis/analogs.md`** (optional fill — D4): ask one ❓ in the conversation's language — "Fill the analog analysis now via web search (a few minutes)?" — ➡️ recommend `yes` for internal/launch stakes, `skip` for hobby. On yes: WebSearch for existing solutions to `$ARGUMENTS`, fill 2-5 rows (what to copy / what to avoid, sources, today's date in Checked); machine-filled rows are proposals — they go through the Phase 4.5 confirmation like everything else. On skip: leave the template's empty state; `/plan-improve` fills later.

Use Context7 if available to ground stack-specific advice:
```
mcp__plugin_context7-plugin_context7__resolve-library-id { libraryName: "<framework>" }
mcp__plugin_context7-plugin_context7__query-docs { id: "<resolved>", topic: "best practices" }
```

If Context7 lookup fails, continue without it.

---

## Phase 4.5: Confirm the drafted plan (BEFORE the first commit)

Everything Phase 4 drafted beyond the user's confirmed answers is a machine proposal — it must be reviewed BEFORE it becomes ground truth for every future gate.

Present, line by line, for confirm / edit / delete:
1. The proposed feature list (`docs/features.md` Planned section, F-001…) — each line answerable by number: keep / rename / drop.
2. The roadmap ordering (Now / Next / Later) — plus the "Explicitly NOT doing" entries, which must trace to the user's own negative-scope answers; machine-added entries are flagged as such.
3. The §6 hard constraints.
4. Machine-filled `docs/analysis/analogs.md` rows, if the optional fill ran — unconfirmed rows keep `(proposed — unconfirmed)` in their "What to copy"/"What to avoid" cells (the gate-1 critic must not treat unconfirmed rows as ground truth).

Rules:
- Wait for the user's pass over the list (no timeouts). Bulk answers are fine ("всё ок, кроме 3 и 5").
- Any line the user does not explicitly confirm keeps the suffix `(proposed — unconfirmed)` in the file. `/plan-improve` clears the tag when the item is later confirmed or reworked.
- Apply edits, then proceed to Phase 5.

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
Stack: <confirmed stack answer>
Pipeline: ai-pipeline plugin (see docs-meta/PIPELINE.md)
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
  - docs/risks.md, docs/glossary.md (seeded), docs/analysis/analogs.md
  - docs-meta/PIPELINE.md, docs-meta/LESSON_FORMAT.md, docs-meta/ELICITATION.md
  - docs-meta/SPEC_FORMAT.md, docs-meta/REQUIREMENTS_FORMAT.md, docs-meta/ADR_FORMAT.md
  - .claude/settings.json (ai-pipeline plugin enabled)
  - .claude/lessons/, docs/superpowers/{specs,plans,critic-reports}/

Initialized:
  - git (first commit: <sha>)
  - beads (epic: <epic-id>)  [or: skipped — bd not installed]
  - Playwright MCP             [or: skipped — npx missing]

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
| User declines the Phase 2 interview | Stop — /init cannot invent a plan the user never confirmed |
| User skips lines in Phase 4.5 confirmation | Keep `(proposed — unconfirmed)` tags on skipped lines, continue |

## Constraints

- /init MUST work in a brand-new empty folder
- /init MUST NOT touch files outside the cwd
- /init MUST NOT install Node modules, Python packages, or any application dependencies
- /init MUST NOT push to any git remote (user pushes manually if desired)
