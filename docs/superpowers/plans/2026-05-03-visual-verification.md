# Visual Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Playwright-MCP-driven visual sub-step inside Phase 9 of `/feature`, `/improve`, `/fix` so the pipeline catches UI regressions for frontend projects before merging.

**Architecture:** New visual sub-step lives inside Phase 9 of `commands/feature.md` (the canonical place). `commands/improve.md` and `commands/fix.md` already reference "Phase 9 of /feature" by design, so they inherit automatically. `/init` gains a Playwright-MCP install step. A new `pipeline.visual_verify` block in the settings template controls behavior. Senior-critic gains a small "read visual evidence if present" step at gate-2.

**Tech Stack:** Bash + jq (already required), Playwright MCP (new prereq), curl (for dev-server probe), markdown (slash-command files), `claude mcp` CLI.

**Spec:** `docs/superpowers/specs/2026-05-03-visual-verification-design.md`

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `assets/templates/settings.json` | Modify | Add `pipeline.visual_verify` block |
| `commands/init.md` | Modify | Detect & install Playwright MCP; report it |
| `commands/feature.md` | Modify | Add visual sub-step to Phase 9; add brainstorm hint to Phase 2 |
| `commands/improve.md` | Modify | One-line note that visual sub-step is inherited from /feature |
| `commands/fix.md` | Modify | One-line note in Phase 7 |
| `agents/senior-critic.md` | Modify | At gate-2, read visual evidence summary if present |
| `assets/templates/CLAUDE.md` | Modify | Document Playwright MCP as 6th context layer |
| `assets/templates/PIPELINE.md` | Modify | Add visual sub-step + 6th context-layer row |
| `README.md` | Modify | Bump feature list, mention v0.3.0 |
| `README_RU.md` | Modify | Same in Russian |
| `docs/WORKFLOW_GUIDE_RU.md` | Modify | Document the new gate |
| `.claude-plugin/plugin.json` | Modify | Version 0.2.0 → 0.3.0 |
| `.claude-plugin/marketplace.json` | Modify | Version 0.2.0 → 0.3.0 |
| `CLAUDE.md` (plugin contributor) | Modify | Note new prereq, add hard rule |

No new files. All edits to existing.

---

## Task 1: Add `pipeline.visual_verify` block to settings template

**Files:**
- Modify: `assets/templates/settings.json`

- [ ] **Step 1: Verify current settings.json shape**

Run: `jq '.pipeline' assets/templates/settings.json`
Expected: `{ "finish_mode": "merge" }`

- [ ] **Step 2: Replace `pipeline` block in settings.json**

Use Edit on `assets/templates/settings.json`:

old_string:
```
  "pipeline": {
    "finish_mode": "merge"
  },
```

new_string:
```
  "pipeline": {
    "finish_mode": "merge",
    "visual_verify": {
      "mode": "required",
      "base_url": "http://localhost:3000",
      "dev_command": "auto",
      "dev_port_timeout_sec": 60,
      "fail_on_console_error": true
    }
  },
```

- [ ] **Step 3: Verify JSON still parses**

Run: `jq '.pipeline.visual_verify.mode' assets/templates/settings.json`
Expected: `"required"`

- [ ] **Step 4: Commit**

```bash
git add assets/templates/settings.json
git commit -m "feat(settings): add pipeline.visual_verify block (v0.3.0)"
```

---

## Task 2: Add Playwright MCP install logic to `/init`

**Files:**
- Modify: `commands/init.md` (Phase 1 prereq scan)

- [ ] **Step 1: Read current Phase 1 to confirm Serena block location**

Run: `grep -n "SERENA_MCP_NOT_REGISTERED\|^## Phase 2:" commands/init.md`
Expected: shows `Phase 1 ... SERENA ... line N` and `## Phase 2: line M` where N < M.

- [ ] **Step 2: Insert Playwright MCP detection block**

Use Edit on `commands/init.md`:

old_string:
```
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

## Phase 2: Clarify (3 multi-choice questions)
```

new_string:
```
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
       claude mcp add --scope user playwright -- npx '@playwright/mcp@latest' 2>&1 | tail -3
     fi
     ```
   - On any failure: print warning with the exact failed command, continue.

   If `NPX_MISSING`, print:
   ```
   npx not found (Node.js missing). Install Node 18+ to enable visual-verify gate.
   Then re-enable in this project:
     claude mcp add --scope user playwright -- npx '@playwright/mcp@latest'
   Continuing without Playwright MCP — visual-verify gate will be skipped for frontend projects.
   ```

---

## Phase 2: Clarify (3 multi-choice questions)
```

- [ ] **Step 3: Verify the insert by grep**

Run: `grep -n "Playwright MCP\|@playwright/mcp" commands/init.md`
Expected: at least 4 matches inside Phase 1 region.

- [ ] **Step 4: Verify Phase 2 marker still exists exactly once**

Run: `grep -c "^## Phase 2: Clarify" commands/init.md`
Expected: `1`

- [ ] **Step 5: Commit**

```bash
git add commands/init.md
git commit -m "feat(init): detect and install Playwright MCP in Phase 1"
```

---

## Task 3: Update `/init` Phase 7 (Report) to mention Playwright MCP

**Files:**
- Modify: `commands/init.md` (Phase 7 report block)

- [ ] **Step 1: Locate report block**

Run: `grep -n "Initialized:\|Next steps:" commands/init.md`
Expected: shows the report section in Phase 7.

- [ ] **Step 2: Update the "Initialized:" lines**

Use Edit on `commands/init.md`:

old_string:
```
Initialized:
  - git (first commit: <sha>)
  - beads (epic: <epic-id>)  [or: skipped — bd not installed]
```

new_string:
```
Initialized:
  - git (first commit: <sha>)
  - beads (epic: <epic-id>)  [or: skipped — bd not installed]
  - Playwright MCP             [or: skipped — npx missing]
```

- [ ] **Step 3: Verify**

Run: `grep -n "Playwright MCP" commands/init.md | tail -5`
Expected: includes the Phase 7 report line.

- [ ] **Step 4: Commit**

```bash
git add commands/init.md
git commit -m "feat(init): show Playwright MCP status in final report"
```

---

## Task 4: Add visual sub-step to `/feature` Phase 9 (canonical block)

**Files:**
- Modify: `commands/feature.md` (Phase 9, also Phase 2 hint)

- [ ] **Step 1: Add `## URLs to verify` hint to Phase 2 (brainstorm)**

Use Edit on `commands/feature.md`:

old_string:
```
The brainstorming skill produces a spec. Save it to:
```
docs/superpowers/specs/<SLUG>.md
```

If the brainstorm has a real clarifying question (not stylistic), ask the user. Wait for answer. Otherwise proceed silently.
```

new_string:
```
The brainstorming skill produces a spec. Save it to:
```
docs/superpowers/specs/<SLUG>.md
```

**Frontend hint (NEW):** If the project has a frontend (`package.json` deps include `react|vue|svelte|next|nuxt|@angular/core|solid-js|preact|@builder.io/qwik|astro` OR a root `index.html` exists), the spec MUST include a section:

```markdown
## URLs to verify
- /
- /<other-path-touched-by-this-feature>
```

If the brainstorm output omits this section for a frontend project, add it with at least `- /`. The visual sub-step in Phase 9 will navigate to each path.

If the brainstorm has a real clarifying question (not stylistic), ask the user. Wait for answer. Otherwise proceed silently.
```

- [ ] **Step 2: Verify Phase 2 hint inserted**

Run: `grep -n "URLs to verify" commands/feature.md`
Expected: at least one match in Phase 2 region.

- [ ] **Step 3: Append visual sub-step to end of Phase 9**

Use Edit on `commands/feature.md`:

old_string:
```
## Phase 9: Verify

Invoke `superpowers:verification-before-completion`. Identify and run the proving command(s) for this feature:
- Test suite: `<project's test command>`
- Lint: `<lint command if configured>`
- Type check: `<typecheck command if configured>`
- Build: `<build command if configured>`

For each: run fresh, read full output, capture exit code. If any fail → STOP, surface output, do not proceed.

---

## Phase 10: Finish
```

new_string:
```
## Phase 9: Verify

Invoke `superpowers:verification-before-completion`. Identify and run the proving command(s) for this feature:
- Test suite: `<project's test command>`
- Lint: `<lint command if configured>`
- Type check: `<typecheck command if configured>`
- Build: `<build command if configured>`

For each: run fresh, read full output, capture exit code. If any fail → STOP, surface output, do not proceed.

### Phase 9b: Visual verification (frontend only)

After the proving commands above pass, run a visual gate **only for frontend projects**.

**Detect frontend:**

```bash
HAS_FRONTEND=no
if [ -f package.json ]; then
  jq -e '.dependencies + .devDependencies | keys[] |
    test("^(react|vue|svelte|next|nuxt|@angular/core|solid-js|preact|@builder.io/qwik|astro)$")' \
    package.json >/dev/null 2>&1 && HAS_FRONTEND=yes
fi
[ -f index.html ] && HAS_FRONTEND=yes
```

If `HAS_FRONTEND=no` → skip directly to Phase 10.

**Read settings:**

```bash
MODE=$(jq -r '.pipeline.visual_verify.mode // "required"' .claude/settings.json)
BASE_URL=$(jq -r '.pipeline.visual_verify.base_url // "http://localhost:3000"' .claude/settings.json)
DEV_CMD=$(jq -r '.pipeline.visual_verify.dev_command // "auto"' .claude/settings.json)
TIMEOUT=$(jq -r '.pipeline.visual_verify.dev_port_timeout_sec // 60' .claude/settings.json)
FAIL_CONSOLE=$(jq -r '.pipeline.visual_verify.fail_on_console_error // true' .claude/settings.json)
```

If `MODE=skip` → skip to Phase 10.

**Verify Playwright MCP is registered:**

```bash
claude mcp list 2>/dev/null | grep -q "^playwright:" || {
  echo "FAIL: Playwright MCP not registered. Run: claude mcp add --scope user playwright -- npx '@playwright/mcp@latest'"
  [ "$MODE" = "required" ] && exit 1 || { echo "WARN: skipping visual sub-step"; SKIP_VISUAL=yes; }
}
```

If `SKIP_VISUAL=yes` → skip to Phase 10.

**Probe / start dev server (hybrid):**

```bash
DEV_PID=""
if curl -sf -o /dev/null -m 2 "$BASE_URL"; then
  echo "Reusing existing dev server at $BASE_URL"
else
  if [ "$DEV_CMD" = "auto" ]; then
    if jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
      DEV_CMD="npm run dev"
    elif jq -e '.scripts.start' package.json >/dev/null 2>&1; then
      DEV_CMD="npm run start"
    else
      echo "FAIL: no scripts.dev / scripts.start in package.json. Set pipeline.visual_verify.dev_command."
      [ "$MODE" = "required" ] && exit 1 || SKIP_VISUAL=yes
    fi
  fi
  if [ -z "$SKIP_VISUAL" ]; then
    bash -c "$DEV_CMD" >/tmp/ai-pipeline-dev.log 2>&1 &
    DEV_PID=$!
    trap "[ -n \"$DEV_PID\" ] && kill $DEV_PID 2>/dev/null" EXIT
    UP=no
    for i in $(seq 1 $TIMEOUT); do
      if curl -sf -o /dev/null -m 2 "$BASE_URL"; then
        echo "Dev server up after ${i}s"
        UP=yes
        break
      fi
      sleep 1
    done
    if [ "$UP" = "no" ]; then
      kill $DEV_PID 2>/dev/null
      echo "FAIL: dev server did not answer 200 OK in ${TIMEOUT}s. Log: /tmp/ai-pipeline-dev.log"
      [ "$MODE" = "required" ] && exit 1 || SKIP_VISUAL=yes
    fi
  fi
fi
```

If `SKIP_VISUAL=yes` → skip to Phase 10.

**Extract URLs from spec:**

```bash
URLS=$(awk '/^## URLs to verify/{flag=1; next} /^## /{flag=0} flag && /^- /' \
  docs/superpowers/specs/<SLUG>.md | sed -E 's/^- //; s|^https?://[^/]+||' | grep -E '^/' || true)
[ -z "$URLS" ] && URLS="/"
```

**Make evidence dirs:**

```bash
EVIDENCE_DIR="docs/superpowers/visual-evidence/<SLUG>"
mkdir -p "$EVIDENCE_DIR/screenshots" "$EVIDENCE_DIR/snapshots"
> "$EVIDENCE_DIR/console.txt"
```

**Slugify helper (compute per URL):**

For each URL `path`, compute `urlslug`:
- `/` → `_root`
- otherwise: lowercase, strip `?...` query, replace any non-alphanumeric with `_`, collapse repeats, trim leading/trailing `_`.

Bash:
```bash
slugify() {
  case "$1" in
    /) echo _root ;;
    *) echo "$1" | sed -E 's|\?.*||; s|^/||; s|/|_|g; s|[^a-zA-Z0-9_]|_|g; s|__+|_|g; s|^_||; s|_$||' | tr A-Z a-z ;;
  esac
}
```

**For each URL, drive Playwright MCP** (these are MCP tool calls, not bash):

For each `path` in `$URLS`:

1. `mcp__playwright__browser_navigate({ url: "<BASE_URL><path>" })`
2. `mcp__playwright__browser_snapshot({ filename: "<EVIDENCE_DIR>/snapshots/<urlslug>.md" })`
3. `mcp__playwright__browser_take_screenshot({ type: "png", fullPage: true, filename: "<EVIDENCE_DIR>/screenshots/<urlslug>.png" })`
4. `mcp__playwright__browser_console_messages({ level: "warning" })`

After step 4, append to `<EVIDENCE_DIR>/console.txt`:
```
=== <path> ===
<the console messages text>
```

**Analyze and write verdict:**

```bash
VERDICT=PASS
REASONS=""
for path in $URLS; do
  s=$(slugify "$path")
  png="$EVIDENCE_DIR/screenshots/${s}.png"
  snap="$EVIDENCE_DIR/snapshots/${s}.md"
  if [ ! -s "$png" ]; then
    VERDICT=FAIL; REASONS="$REASONS
- $path: screenshot missing"
  else
    sz=$(stat -f%z "$png" 2>/dev/null || stat -c%s "$png" 2>/dev/null)
    if [ "$sz" -lt 1024 ]; then
      VERDICT=FAIL; REASONS="$REASONS
- $path: screenshot < 1KB (likely blank)"
    fi
  fi
  if [ ! -s "$snap" ]; then
    VERDICT=FAIL; REASONS="$REASONS
- $path: accessibility snapshot empty"
  fi
done
if [ "$FAIL_CONSOLE" = "true" ] && grep -qiE "\\[error\\]|console\\.error|TypeError|ReferenceError" "$EVIDENCE_DIR/console.txt" 2>/dev/null; then
  VERDICT=FAIL; REASONS="$REASONS
- console error(s) detected — see console.txt"
fi

cat > "$EVIDENCE_DIR/summary.md" <<EOF
# Visual verification summary

**Slug:** <SLUG>
**Date:** $(date -Iseconds 2>/dev/null || date)
**Mode:** $MODE
**Base URL:** $BASE_URL
**URLs visited:** $(echo $URLS | tr '\n' ' ')
**Verdict:** $VERDICT

## Reasons (if FAIL)
$REASONS

## Files
- screenshots/ — PNG per URL
- snapshots/   — accessibility tree per URL
- console.txt  — browser console output per URL
EOF
```

**Cleanup dev server:**

```bash
[ -n "$DEV_PID" ] && kill $DEV_PID 2>/dev/null && echo "Killed dev server PID $DEV_PID"
```

**Apply verdict:**

- `VERDICT=PASS` → proceed to Phase 10.
- `VERDICT=FAIL` and `MODE=required` → STOP. Print contents of `summary.md`. Do NOT merge.
- `VERDICT=FAIL` and `MODE=best_effort` → warn, print summary, proceed to Phase 10.

---

## Phase 10: Finish
```

- [ ] **Step 4: Verify the insert**

Run: `grep -n "Phase 9b\|browser_navigate\|browser_take_screenshot" commands/feature.md`
Expected: each appears at least once.

- [ ] **Step 5: Verify Phase 10 marker remains exactly once**

Run: `grep -c "^## Phase 10: Finish" commands/feature.md`
Expected: `1`

- [ ] **Step 6: Commit**

```bash
git add commands/feature.md
git commit -m "feat(feature): add Playwright-MCP visual sub-step to Phase 9"
```

---

## Task 5: Annotate `/improve` to inherit visual sub-step

**Files:**
- Modify: `commands/improve.md`

`/improve` already says "All other phases run identically to /feature... do not duplicate it here." That sentence is enough to inherit Phase 9b. Add a one-line confirmation in the "Differences" list so it's explicit.

- [ ] **Step 1: Locate the differences list**

Run: `grep -n "Differences in specific phases\|Phase 8 (Critic gate-2)\|Phase 11 (Master Plan update)" commands/improve.md`

- [ ] **Step 2: Add explicit Phase 9 line**

Use Edit on `commands/improve.md`:

old_string:
```
- **Phase 8 (Critic gate-2):** The critic should be told this is an improvement; it pays special attention to "did this break the existing behavior the feature already shipped?" and "are there regression tests?"
- **Phase 11 (Master Plan update):** Do NOT move anything in `docs/features.md` (the feature was already Shipped). Just remove the `(behavior change in progress)` note. Optionally append a `- behavior changed YYYY-MM-DD: <slug>` sub-bullet under the feature.
```

new_string:
```
- **Phase 8 (Critic gate-2):** The critic should be told this is an improvement; it pays special attention to "did this break the existing behavior the feature already shipped?" and "are there regression tests?"
- **Phase 9 (Verify, including 9b visual):** Inherited from `/feature` Phase 9 — visual sub-step runs for frontend projects. The brainstorm in Phase 2 must include `## URLs to verify` listing the affected paths (the changed routes plus any cross-impacted views). For an improvement that doesn't change any URL, list at least `/`.
- **Phase 11 (Master Plan update):** Do NOT move anything in `docs/features.md` (the feature was already Shipped). Just remove the `(behavior change in progress)` note. Optionally append a `- behavior changed YYYY-MM-DD: <slug>` sub-bullet under the feature.
```

- [ ] **Step 3: Verify**

Run: `grep -n "Phase 9 (Verify, including 9b visual)" commands/improve.md`
Expected: 1 match.

- [ ] **Step 4: Commit**

```bash
git add commands/improve.md
git commit -m "docs(improve): explicit Phase 9 visual-gate inheritance note"
```

---

## Task 6: Annotate `/fix` Phase 7 to inherit visual sub-step

**Files:**
- Modify: `commands/fix.md`

- [ ] **Step 1: Locate Phase 7**

Run: `grep -n "^## Phase 7: Verify" commands/fix.md`
Expected: 1 match.

- [ ] **Step 2: Replace Phase 7 body**

Use Edit on `commands/fix.md`:

old_string:
```
## Phase 7: Verify

Same as `/feature` Phase 9. Plus: explicitly run the test from Phase 2 to prove the bug is fixed.
```

new_string:
```
## Phase 7: Verify

Same as `/feature` Phase 9 (including the visual sub-step 9b for frontend projects). Plus: explicitly run the test from Phase 2 to prove the bug is fixed.

If this bug touches UI behavior, the spec at `docs/superpowers/specs/<SLUG>-diagnosis.md` should include a `## URLs to verify` section listing the page(s) where the bug manifested. The visual sub-step will catch unfixed regressions even if the unit test passes.
```

- [ ] **Step 3: Verify**

Run: `grep -n "9b for frontend\|URLs to verify" commands/fix.md`
Expected: at least 2 matches.

- [ ] **Step 4: Commit**

```bash
git add commands/fix.md
git commit -m "docs(fix): note that visual sub-step inherits in Phase 7"
```

---

## Task 7: Update `senior-critic` to read visual evidence at gate-2

**Files:**
- Modify: `agents/senior-critic.md`

- [ ] **Step 1: Locate gate-2 input list**

Run: `grep -n "Gate 2: post-implementation\|All files under \`.claude/lessons/\`" agents/senior-critic.md`

- [ ] **Step 2: Extend gate-2 input list and look-fors**

Use Edit on `agents/senior-critic.md`:

old_string:
```
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
```

new_string:
```
### Gate 2: post-implementation (reviewing a diff)

You receive:
- The base branch and the head branch (run `git diff base..head` to see the change)
- The spec it was built from
- `docs/architecture.md`, `docs/features.md`
- All files under `.claude/lessons/`
- **Visual evidence (if exists):** `docs/superpowers/visual-evidence/<slug>/summary.md` and the `snapshots/` text files. Do NOT open PNGs — those are for the human reviewer.

Look for:
- Behaviors claimed in the spec but missing in the code or tests
- Security issues (auth bypass, input validation, secret leakage, injection vectors, missing rate limits)
- Error handling gaps (try/except swallowing details, missing retries, no fallback path)
- Lesson violations (cite the lesson filename)
- Tests that pass but don't actually exercise the claimed behavior (assertion-on-self, mocked the thing under test, etc.)
- Architecture drift (new dependencies not justified, boundaries crossed, modules now too large)
- **Visual drift (if visual-evidence/<slug>/summary.md exists):**
  - URLs declared in spec's `## URLs to verify` but not visited (per `summary.md`'s `URLs visited` line) — flag as **Important**.
  - Verdict=PASS but `console.txt` contains errors — flag as **Important** (mode mismatch).
  - Snapshot text indicating empty `<main>`/`<body>` or "Application error" overlays — flag as **Critical**.
```

- [ ] **Step 3: Verify**

Run: `grep -n "visual-evidence\|Visual drift" agents/senior-critic.md`
Expected: at least 3 matches.

- [ ] **Step 4: Commit**

```bash
git add agents/senior-critic.md
git commit -m "feat(critic): read visual evidence at gate-2"
```

---

## Task 8: Update template `CLAUDE.md` — Playwright MCP as 6th context layer

**Files:**
- Modify: `assets/templates/CLAUDE.md`

- [ ] **Step 1: Locate Plugins section**

Run: `grep -n "^## Plugins (assumed installed)" assets/templates/CLAUDE.md`
Expected: 1 match.

- [ ] **Step 2: Append Playwright MCP block after Plugins section**

Use Edit on `assets/templates/CLAUDE.md`:

old_string:
```
## Plugins (assumed installed)

- `superpowers` — TDD, brainstorming, debugging, verification, code-review, worktrees, finishing
- `beads` — persistent task tracking across sessions
- `template-bridge` — 413+ specialist agent templates on demand
- `context7-plugin` — live library docs

If any are missing, the orchestrator should warn but continue with degraded behavior.
```

new_string:
```
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

Settings live under `.claude/settings.json` → `pipeline.visual_verify`:

| Field | Default | Meaning |
|---|---|---|
| `mode` | `required` | `required` / `best_effort` / `skip` |
| `base_url` | `http://localhost:3000` | probed first; if not reachable, pipeline starts dev server |
| `dev_command` | `auto` | `auto` reads `package.json scripts.dev`; otherwise explicit shell command |
| `dev_port_timeout_sec` | `60` | max wait for dev server boot |
| `fail_on_console_error` | `true` | console errors fail the gate in `required` mode |

Evidence is stored at `docs/superpowers/visual-evidence/<slug>/`.
```

- [ ] **Step 3: Verify**

Run: `grep -n "Playwright MCP\|visual_verify" assets/templates/CLAUDE.md`
Expected: at least 4 matches.

- [ ] **Step 4: Commit**

```bash
git add assets/templates/CLAUDE.md
git commit -m "docs(template): document Playwright MCP visual gate in CLAUDE.md"
```

---

## Task 9: Update `PIPELINE.md` template — phase row + 6th context layer

**Files:**
- Modify: `assets/templates/PIPELINE.md`

- [ ] **Step 1: Add 9b row in the "Internal phases" table**

Use Edit on `assets/templates/PIPELINE.md`:

old_string:
```
| 9 | verify | Runs proving commands, reads exit codes | `superpowers:verification-before-completion` |
| 10 | finish | Merges to main OR opens PR (per `pipeline.finish_mode` in settings.json) | `superpowers:finishing-a-development-branch` |
```

new_string:
```
| 9 | verify | Runs proving commands, reads exit codes | `superpowers:verification-before-completion` |
| 9b | visual-verify (frontend only) | Drives Playwright MCP across spec's `## URLs to verify`, captures screenshot + a11y snapshot + console; verdict in `docs/superpowers/visual-evidence/<slug>/summary.md` | inline in command file |
| 10 | finish | Merges to main OR opens PR (per `pipeline.finish_mode` in settings.json) | `superpowers:finishing-a-development-branch` |
```

- [ ] **Step 2: Add Playwright row to context-layers table**

Use Edit on `assets/templates/PIPELINE.md`:

old_string:
```
The pipeline reads from 5 context layers:

| Layer | Storage | Stores | Read in | Written in |
|---|---|---|---|---|
| **Beads** | `.beads/` | tasks + dependencies | every `bd ready` | every command |
| **Lessons** | `.claude/lessons/*.md` | bug prevention rules | every phase (lesson trigger match) | `/fix`, `/lesson` |
| **Master Plan** | `docs/{architecture,features,roadmap}.md` | what+how+priorities | ground phase | `/init`, `/plan-improve`, `/feature` (features.md only) |
| **Context7** | live MCP query | external library docs | ground phase | n/a (read-only) |
| **Serena memory** | `.serena/memories/*.md` | project conventions + design decisions | `/feature`/`/improve` ground | senior-critic at gate-2 (gate-1 for `/plan-improve`), `/remember` |
```

new_string:
```
The pipeline reads from 6 context layers:

| Layer | Storage | Stores | Read in | Written in |
|---|---|---|---|---|
| **Beads** | `.beads/` | tasks + dependencies | every `bd ready` | every command |
| **Lessons** | `.claude/lessons/*.md` | bug prevention rules | every phase (lesson trigger match) | `/fix`, `/lesson` |
| **Master Plan** | `docs/{architecture,features,roadmap}.md` | what+how+priorities | ground phase | `/init`, `/plan-improve`, `/feature` (features.md only) |
| **Context7** | live MCP query | external library docs | ground phase | n/a (read-only) |
| **Serena memory** | `.serena/memories/*.md` | project conventions + design decisions | `/feature`/`/improve` ground | senior-critic at gate-2 (gate-1 for `/plan-improve`), `/remember` |
| **Playwright MCP** | live browser session | live UI state (screenshots, a11y, console) | Phase 9b of `/feature`, `/improve`, `/fix` | n/a (read-only — evidence lands in `docs/superpowers/visual-evidence/<slug>/`) |
```

- [ ] **Step 3: Update the "5 context layers" mention to "6"**

Already covered in Step 2 ("from 5" → "from 6"). Verify with: `grep -n "context layers" assets/templates/PIPELINE.md`
Expected: shows "from 6 context layers".

- [ ] **Step 4: Verify both edits**

Run: `grep -nE "9b\|visual-verify|Playwright MCP" assets/templates/PIPELINE.md`
Expected: phase-table row + context-layer row.

- [ ] **Step 5: Commit**

```bash
git add assets/templates/PIPELINE.md
git commit -m "docs(template): add 9b visual-verify row + Playwright context layer to PIPELINE.md"
```

---

## Task 10: Update `README.md` and `README_RU.md`

**Files:**
- Modify: `README.md`
- Modify: `README_RU.md`

- [ ] **Step 1: Inspect README features sections**

Run: `grep -n "## What\|## Что\|v0\\.[0-9]\\.[0-9]" README.md README_RU.md`

- [ ] **Step 2: Update English README**

Find a feature-list bullet block in `README.md` and use Edit to add a visual-gate bullet. The exact old_string / new_string must be derived by reading the file at the time of execution — pattern:

old_string (read-time): the last bullet of the "what's new in v0.2.0" section, or the equivalent feature list.

new_string: same content + a new bullet:
```
- **Visual verification gate (v0.3.0)** — for frontend projects, Phase 9 drives Playwright MCP across the URLs listed in the spec, captures screenshots + a11y snapshots, fails the pipeline on console errors or blank renders. Configurable via `pipeline.visual_verify` in `.claude/settings.json`.
```

If a "## Pipeline phases" or feature-summary table exists, also add a row for **9b visual-verify**. (Read the file before editing to choose the exact insertion point.)

- [ ] **Step 3: Update Russian README** (`README_RU.md`)

Mirror the change. Russian text:
```
- **Гейт визуальной верификации (v0.3.0)** — для фронтенд-проектов фаза 9 запускает Playwright MCP, открывает URL'ы перечисленные в спеке (`## URLs to verify`), снимает скриншоты + accessibility-снимки и стопит пайплайн при console-ошибках или пустом рендере. Настройки в `.claude/settings.json` → `pipeline.visual_verify`.
```

- [ ] **Step 4: Verify both files mention v0.3.0**

Run: `grep -n "0\\.3\\.0\|visual" README.md README_RU.md | head -10`
Expected: at least one match in each file.

- [ ] **Step 5: Commit**

```bash
git add README.md README_RU.md
git commit -m "docs(readme): add v0.3.0 visual-verify gate to feature list (EN+RU)"
```

---

## Task 11: Update `docs/WORKFLOW_GUIDE_RU.md`

**Files:**
- Modify: `docs/WORKFLOW_GUIDE_RU.md`

- [ ] **Step 1: Locate Phase 9 / verify section in the guide**

Run: `grep -n "Phase 9\|Фаза 9\|verify" docs/WORKFLOW_GUIDE_RU.md`

- [ ] **Step 2: Add a "Визуальная верификация" subsection after the verify mention**

Use Edit at the location identified in Step 1 to insert:

```markdown
### Визуальная верификация (Фаза 9b, v0.3.0)

Для фронтенд-проектов после стандартной фазы verify запускается **визуальный под-этап**: pipeline через Playwright MCP открывает каждый URL из секции `## URLs to verify` в спеке, делает скриншот + a11y snapshot + читает console, и сохраняет всё в `docs/superpowers/visual-evidence/<slug>/`.

**Триггер фронтенда**: `package.json` содержит зависимость на react/vue/svelte/next/nuxt/@angular/core/solid-js/preact/qwik/astro **или** в корне есть `index.html`.

**Жизненный цикл dev-сервера** (гибрид):
1. Сначала пробуем `base_url` (по умолчанию `http://localhost:3000`).
2. Если не отвечает — pipeline стартует `npm run dev` (или `npm run start`) в фоне, ждёт 200 OK до 60 секунд, после визуала убивает процесс.

**Критерии FAIL**: HTTP 4xx/5xx, console.error (при `fail_on_console_error: true`), пустой/чёрный скриншот (<1KB), таймаут dev-сервера.

**Режимы** (`.claude/settings.json` → `pipeline.visual_verify.mode`):
- `required` (по умолчанию) — FAIL стопит pipeline
- `best_effort` — warn и продолжаем
- `skip` — фаза 9b отключена полностью

Если в спеке нет секции `## URLs to verify`, проверяется только `/`.
```

- [ ] **Step 3: Verify**

Run: `grep -n "Визуальная верификация\|9b" docs/WORKFLOW_GUIDE_RU.md`
Expected: at least 2 matches.

- [ ] **Step 4: Commit**

```bash
git add docs/WORKFLOW_GUIDE_RU.md
git commit -m "docs(workflow-ru): document v0.3.0 visual-verify gate"
```

---

## Task 12: Bump version 0.2.0 → 0.3.0

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Verify current version**

Run: `jq -r .version .claude-plugin/plugin.json`
Expected: `0.2.0`

- [ ] **Step 2: Bump plugin.json**

Use Edit on `.claude-plugin/plugin.json`:

old_string:
```
  "description": "6-command AI development pipeline (/init, /plan-improve, /feature, /improve, /fix, /lesson) with auto-critic at two gates and a lessons-learned flywheel. Builds on Superpowers, Beads, Context7.",
  "version": "0.2.0",
```

new_string:
```
  "description": "7-command AI development pipeline (/init, /plan-improve, /feature, /improve, /fix, /lesson, /remember) with auto-critic at two gates, lessons-learned flywheel, Serena memory, and Playwright-MCP visual verification gate for frontend projects. Builds on Superpowers, Beads, Context7.",
  "version": "0.3.0",
```

- [ ] **Step 3: Bump marketplace.json**

Use Edit on `.claude-plugin/marketplace.json`:

old_string:
```
      "description": "6-command AI development pipeline with auto-critic and lessons.",
      "version": "0.2.0"
```

new_string:
```
      "description": "7-command AI development pipeline with auto-critic, lessons, Serena memory, and Playwright-MCP visual gate.",
      "version": "0.3.0"
```

- [ ] **Step 4: Verify both files**

Run: `jq -r .version .claude-plugin/plugin.json; jq -r '.plugins[0].version' .claude-plugin/marketplace.json`
Expected:
```
0.3.0
0.3.0
```

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: bump version 0.2.0 → 0.3.0 (visual-verify gate)"
```

---

## Task 13: Update plugin contributor `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (root, contributor doc)

- [ ] **Step 1: Locate "Hard rules" and "Versioning policy" sections**

Run: `grep -n "## Hard rules\|## Versioning policy\|v0\\.[0-9]" CLAUDE.md`

- [ ] **Step 2: Update versioning-policy footer**

Use Edit on `CLAUDE.md`:

old_string:
```
- v0.2.0 adds Serena memory integration; new prereq is `uv` + `serena-agent` (auto-installed by `/init`)
```

new_string:
```
- v0.2.0 adds Serena memory integration; new prereq is `uv` + `serena-agent` (auto-installed by `/init`)
- v0.3.0 adds Playwright-MCP visual-verify gate for frontend projects; new prereq is `npx @playwright/mcp@latest` registered as MCP server (auto-registered by `/init` if `npx` is available)
```

- [ ] **Step 3: Add Hard Rule 8 (visual gate consistency)**

Use Edit on `CLAUDE.md`:

old_string:
```
7. **Serena memory is the 5th context layer.** Any change to `commands/feature.md`, `commands/improve.md`, `commands/plan-improve.md`, or `agents/senior-critic.md` must keep the memory read/write logic intact (Phase 1 ground reads memories; gates auto-write suggested memories from the critic). Do not duplicate memory writes across multiple commands.
```

new_string:
```
7. **Serena memory is the 5th context layer.** Any change to `commands/feature.md`, `commands/improve.md`, `commands/plan-improve.md`, or `agents/senior-critic.md` must keep the memory read/write logic intact (Phase 1 ground reads memories; gates auto-write suggested memories from the critic). Do not duplicate memory writes across multiple commands.
8. **Playwright MCP is the 6th context layer (v0.3.0+).** The visual sub-step is canonical only in `commands/feature.md` Phase 9. `/improve` and `/fix` reference it; do NOT duplicate the bash/MCP block. The settings schema (`pipeline.visual_verify` in `assets/templates/settings.json`) is the source of truth for behavior; any new field must be reflected in `assets/templates/CLAUDE.md` and `assets/templates/PIPELINE.md`.
```

- [ ] **Step 4: Verify**

Run: `grep -n "v0\\.3\\.0\|Playwright MCP is the 6th" CLAUDE.md`
Expected: 2 matches.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(contributor): add v0.3.0 Playwright MCP rule and prereq note"
```

---

## Task 14: Smoke test (final verification)

**Files:** none — this is a verification task that produces no commits in the plugin repo.

- [ ] **Step 1: Set up smoke-test workspace**

```bash
SMOKE_DIR="/tmp/ai-pipeline-viz-smoke-$$"
mkdir -p "$SMOKE_DIR"
cd "$SMOKE_DIR"
npm create vite@latest . -- --template react-ts
npm install
```

Expected: `package.json`, `vite.config.ts`, `src/` present.

- [ ] **Step 2: Re-add the plugin marketplace (in case version was cached)**

```bash
claude plugin marketplace remove ai-pipeline-marketplace 2>/dev/null
claude plugin marketplace add /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
```

Expected: marketplace registered, no errors.

- [ ] **Step 3: Run /init via Claude in the smoke dir**

In a separate `claude` session inside `$SMOKE_DIR`:
```
/init "viz smoke test app"
```

Then verify from outside:
```bash
jq '.pipeline.visual_verify' "$SMOKE_DIR/.claude/settings.json"
claude mcp list 2>/dev/null | grep playwright
```

Expected:
- jq output includes `"mode": "required"`, `"base_url": "http://localhost:3000"`, etc.
- `claude mcp list` shows `playwright: ...`

- [ ] **Step 4: Test the positive path**

In the smoke `claude` session, edit `docs/superpowers/specs/<auto-generated-slug>.md` after brainstorm to ensure it includes:
```markdown
## URLs to verify
- /
```

Run:
```
/feature "add a visible h1 saying hello to the home page"
```

Verify after completion:
```bash
ls "$SMOKE_DIR/docs/superpowers/visual-evidence/"*/screenshots/_root.png
ls "$SMOKE_DIR/docs/superpowers/visual-evidence/"*/snapshots/_root.md
cat "$SMOKE_DIR/docs/superpowers/visual-evidence/"*/summary.md | grep "Verdict"
```

Expected:
- `_root.png` exists, > 1KB
- `_root.md` exists, non-empty
- `summary.md` contains `Verdict: PASS`

- [ ] **Step 5: Test the negative path**

In the same session:
```
/feature "add a /broken route whose component throws on render with a console.error"
```

After spec brainstorm, ensure it has:
```markdown
## URLs to verify
- /broken
```

Expected:
- Pipeline reaches Phase 9 visual sub-step.
- `summary.md` shows `Verdict: FAIL`.
- Pipeline STOPS — no merge happens. `git log main..HEAD` still shows the feature branch unmerged.

- [ ] **Step 6: Test best_effort fallback**

```bash
jq '.pipeline.visual_verify.mode = "best_effort"' "$SMOKE_DIR/.claude/settings.json" > /tmp/.s.json && mv /tmp/.s.json "$SMOKE_DIR/.claude/settings.json"
```

Re-run the negative-path /feature with the same broken route.
Expected:
- Pipeline warns, prints summary, but proceeds to Phase 10 and merges.

- [ ] **Step 7: Cleanup**

```bash
cd /
rm -rf "$SMOKE_DIR"
```

- [ ] **Step 8: Tag the release**

After all smoke-test steps PASS, back in the plugin repo:

```bash
cd /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin
git tag v0.3.0
# Note: do NOT push the tag from inside Claude. The user pushes manually.
echo "Tagged v0.3.0. To publish: git push origin main && git push origin v0.3.0"
```

---

## Self-Review

Spec coverage check:

| Spec section | Plan task |
|---|---|
| Component 1 — Playwright MCP install | Task 2 |
| Component 2 — Frontend detector | Task 4 (inline in feature.md Phase 9) |
| Component 3 — Settings schema | Task 1 |
| Component 4 — Dev server manager | Task 4 |
| Component 5 — URL extractor | Task 4 |
| Component 6 — Browser driver | Task 4 |
| Component 7 — Evidence store | Task 4 |
| Component 8 — Pass/fail criteria | Task 4 |
| Component 9 — Critic update | Task 7 |
| Component 10 — Brainstorm hint | Task 4 (Phase 2 hint sub-step) |
| Component 11 — Documentation updates | Tasks 8-11 |
| Versioning | Task 12 |
| Smoke test | Task 14 |
| Inheritance from /improve, /fix | Tasks 5, 6 |
| Plugin contributor docs | Task 13 |

No gaps. No placeholders ("TBD", "etc.") in any task. Type/name consistency: `pipeline.visual_verify.mode`, `MODE`, `BASE_URL`, `DEV_PID`, `EVIDENCE_DIR`, `URLS`, `VERDICT` are used consistently across Tasks 1, 4, 7, 8, 9, 11.

Open questions from the spec, status:

- Exact Playwright MCP tool names: **resolved** via Context7 — `browser_navigate`, `browser_snapshot`, `browser_take_screenshot`, `browser_console_messages`. Used in Task 4.
- Pixel-variance heuristic: **deferred** — Task 4 uses file-size threshold (1KB) only. Variance check left for a future beads task.
- Evidence in PR body: **deferred** — Phase 10 PR template untouched in this plan. A future minor task can add a `## Visual evidence` section to the PR body listing screenshot relative paths.
