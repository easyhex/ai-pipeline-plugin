---
description: Build new functionality end-to-end. Full automatic pipeline (ground → brainstorm → critic → plan → TDD → critic → verify → finish). User intervenes only on real clarifying questions or Critical critic findings.
argument-hint: "<feature description>"
---

# /feature — build new functionality (full auto pipeline)

**Input:** `$ARGUMENTS` (the feature description)

## Pre-flight

1. **Master Plan must exist:**
   - Run: `grep -q "UNFILLED" docs/architecture.md 2>/dev/null && echo unfilled || echo filled`
   - If `unfilled` → STOP. Print: "Run `/init \"<app description>\"` first."

2. **Generate slug:**
   - Take first 4-6 meaningful words from `$ARGUMENTS`
   - Convert to lowercase, hyphenate
   - Format: `YYYY-MM-DD-<slug>` (use today's date)
   - Save as `$SLUG` for use in filenames throughout

3. **Announce intent:**
   - Tell the user: "Starting /feature pipeline for: <description>. Slug: <SLUG>. I'll proceed automatically through 11 phases. I'll only stop for real clarifying questions or Critical critic findings."

---

## Phase 1: Ground

Read in full:
- `docs/architecture.md`
- `docs/features.md`
- `docs/roadmap.md`
- Every file under `.claude/lessons/`

Detect libraries from package manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, etc.). For each detected library that is *plausibly relevant* to this feature, query Context7:

```
mcp__plugin_context7-plugin_context7__resolve-library-id { libraryName: "<lib>" }
mcp__plugin_context7-plugin_context7__query-docs { id: "<resolved>", topic: "<topic relevant to feature>" }
```

**Memory grounding (NEW):**

Call `mcp__serena__list_memories` to retrieve all memory names. For each name whose slug substring-matches the feature description (`$ARGUMENTS`) OR matches files plausibly affected by this work, call `mcp__serena__read_memory({ name: <name> })` and incorporate its content into your context.

Add a `Memory grounding: N memories loaded (<comma-separated names>)` line to the internal ground summary. If `list_memories` fails (Serena MCP not running), skip this step silently with one note: `Memory grounding: skipped (Serena unavailable)`.

Produce a 5-10 bullet **ground summary** (internal — not shown to user unless asked):
- Architecture context (where this feature fits)
- Existing features it interacts with
- Roadmap position
- Lessons that match this feature's domain (cite filenames)
- Library-specific gotchas from Context7
- Memory grounding results (N memories loaded, or skipped)
- Open questions for brainstorm

---

## Phase 2: Brainstorm

Invoke `superpowers:brainstorming` with:
- The user's feature description
- The ground summary as context

The brainstorming skill produces a spec. Save it to:
```
docs/superpowers/specs/<SLUG>.md
```

**Frontend hint (NEW):** If the project has a frontend (`package.json` deps include `react|vue|svelte|next|nuxt|@angular/core|solid-js|preact|@builder.io/qwik|astro`, OR a root `index.html` exists alongside `package.json`), the spec MUST include a section:

```markdown
## URLs to verify
- /
- /<other-path-touched-by-this-feature>
```

If the brainstorm output omits this section for a frontend project, add it with at least `- /`. The visual sub-step in Phase 9 will navigate to each path.

If the brainstorm has a real clarifying question (not stylistic), ask the user. Wait for answer. Otherwise proceed silently.

---

## Phase 3: Critic gate-1

Invoke the `senior-critic` subagent (ships with this plugin — invoke it by name via the Task tool; it is NOT a file in the user's project):

```
Use the senior-critic subagent to review this spec at gate 1.
Inputs:
  - Spec: docs/superpowers/specs/<SLUG>.md
  - docs/architecture.md, docs/features.md, docs/roadmap.md
  - All files under .claude/lessons/
  - Original user request: "<$ARGUMENTS>"
Slug: <SLUG>
Gate: 1
```

The critic saves a report and returns a one-line summary like:
`critic gate 1: 0 Critical / 2 Important / 1 Nice-to-have. Report: docs/superpowers/critic-reports/<SLUG>-gate1.md`

**Decision:**
- If Critical > 0: present summary to user, ask `continue / address / override`. Default to `address` if user does nothing within 1 message exchange.
  - `address` → re-run Phase 2 with critic findings as additional input. Max 2 retries; if still Critical, force user decision.
  - `override` → user must provide a written reason; append to the report file.
  - `continue` → proceed.
- If Critical == 0: proceed silently. Mention only the one-line summary.

---

## Phase 4: Plan

Invoke `superpowers:writing-plans` on the spec at `docs/superpowers/specs/<SLUG>.md`. Save the plan to:
```
docs/superpowers/plans/<SLUG>.md
```

---

## Phase 5: Beads tasks

For each task in the plan:
```bash
bd create -t task "<task title from plan>" --description "<task description>"
```

Capture the IDs. For sequential tasks (Task N depends on Task N-1):
```bash
bd dep add <task-N-id> <task-N-1-id> --type blocks
```

Create a parent epic for the feature and add `parent-child` deps from each task to the epic:
```bash
# --silent prints only the issue ID; beads ID prefixes are project-derived, never assume "bd-"
EPIC_ID=$(bd create -t epic "<feature description>" --silent)
bd dep add <task-id> $EPIC_ID --type parent-child
```

Update `docs/features.md`: move/add the feature to "In progress" with the epic ID and slug.

---

## Phase 6: Worktree (conditional)

If the plan has > 3 sub-tasks, invoke `superpowers:using-git-worktrees`. This creates a worktree on a branch named `feature/<slug>`.

If ≤ 3 sub-tasks, work directly on a feature branch:
```bash
git checkout -b feature/<slug>
```

---

## Phase 7: TDD loop

Loop until `bd ready` returns no tasks blocked-by this epic:

```
For each ready task:
  - bd update <id> --claim
  - Invoke superpowers:test-driven-development for this task
    (RED → verify-fail → GREEN → verify-pass → REFACTOR)
  - After GREEN: git add -A && git commit -m "feat(<slug>): <task title>"
  - bd close <id> --reason "Done — see commit <sha>"
```

**Stop conditions:**
- 3 failed RED→GREEN attempts on a single task → stop, surface to user
- Test that should fail doesn't fail → stop (test is broken)
- Verification command fails → stop

---

## Phase 8: Critic gate-2

Invoke the `senior-critic` subagent at gate 2:

```
Use the senior-critic subagent to review at gate 2.
Inputs:
  - Diff: git diff main..HEAD (or git diff main..feature/<slug> if in worktree)
  - Spec: docs/superpowers/specs/<SLUG>.md
  - docs/architecture.md, docs/features.md
  - All files under .claude/lessons/
Slug: <SLUG>
Gate: 2
```

Critic saves report, returns one-line summary.

**Auto-write suggested memories (NEW):**

Read the critic's saved report file (path returned in the summary line). Parse the section beginning with `## Memories to capture (suggested)`. For each bullet entry of the form `` - `<slug>`: <summary> — <reason> ``:

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

**Decision:**
- If Critical > 0: present to user, ask `continue / address / override`. Default `address`.
  - `address` → for each Critical/Important finding, run `bd create` to add a new task, then loop back to Phase 7 for those tasks. Max 2 cycles.
  - `override` → require written reason in report.
  - `continue` → proceed.
- If Critical == 0: proceed.

---

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
FRONTEND_RULE=""
if [ -f package.json ]; then
  jq -e '.dependencies + .devDependencies | keys[] |
    test("^(react|vue|svelte|next|nuxt|@angular/core|solid-js|preact|@builder.io/qwik|astro)$")' \
    package.json >/dev/null 2>&1 && { HAS_FRONTEND=yes; FRONTEND_RULE="framework dependency in package.json"; }
fi
# A bare index.html (WASM demo, docs page) must NOT gate a pure compute repo:
# index.html counts only alongside package.json (there is no dev server to probe otherwise).
if [ "$HAS_FRONTEND" = "no" ] && [ -f index.html ] && [ -f package.json ]; then
  HAS_FRONTEND=yes; FRONTEND_RULE="index.html alongside package.json"
fi
[ "$HAS_FRONTEND" = "yes" ] && echo "Frontend detected: $FRONTEND_RULE"
```

If `HAS_FRONTEND=no` → skip directly to Phase 10.

**Read settings:**

```bash
MODE=$(jq -r '.pipeline.visual_verify.mode // "required"' .claude/settings.json)
BASE_URL=$(jq -r '.pipeline.visual_verify.base_url // "http://localhost:3000"' .claude/settings.json)
DEV_CMD=$(jq -r '.pipeline.visual_verify.dev_command // "auto"' .claude/settings.json)
TIMEOUT=$(jq -r '.pipeline.visual_verify.dev_port_timeout_sec // 60' .claude/settings.json)
FAIL_CONSOLE=$(jq -r 'if .pipeline.visual_verify.fail_on_console_error == false then "false" else "true" end' .claude/settings.json 2>/dev/null || echo true)
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
    trap '[ -n "$DEV_PID" ] && kill "$DEV_PID" 2>/dev/null' EXIT
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
# Resolve the spec file STATELESSLY, in this block (bash blocks may run as separate
# shells — never rely on a variable set in another block or another command file):
# /feature saves docs/superpowers/specs/<SLUG>.md; /fix saves <SLUG>-diagnosis.md.
SPEC_FILE="docs/superpowers/specs/<SLUG>.md"
[ -f "docs/superpowers/specs/<SLUG>-diagnosis.md" ] && SPEC_FILE="docs/superpowers/specs/<SLUG>-diagnosis.md"
URLS=$(awk '/^## URLs to verify/{flag=1; next} /^## /{flag=0} flag && /^- /' \
  "$SPEC_FILE" | sed -E 's/^- //; s|^https?://[^/]+||' | grep -E '^/' || true)
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
if [ "$FAIL_CONSOLE" = "true" ] && grep -qiE '\[error\]|console\.error|TypeError|ReferenceError' "$EVIDENCE_DIR/console.txt" 2>/dev/null; then
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
trap - EXIT
```

**Apply verdict:**

- `VERDICT=PASS` → proceed to Phase 10.
- `VERDICT=FAIL` and `MODE=required` → STOP. Print contents of `summary.md`. Do NOT merge.
- `VERDICT=FAIL` and `MODE=best_effort` → warn, print summary, proceed to Phase 10.

---

## Phase 10: Finish

Read `.claude/settings.json`'s `pipeline.finish_mode`. Default `merge`.

**If `merge`:**
```bash
git checkout main
git merge --no-ff feature/<slug> -m "feat: <feature description> (merged from feature/<slug>)"
git branch -d feature/<slug>
# If worktree was used:
git worktree remove ../<worktree-dir>
```

**If `pr`:**
```bash
gh pr create \
  --title "feat: <feature description>" \
  --body "$(cat <<EOF
## Summary
<one paragraph from spec>

## Critic review
Gate 1: <summary>
Gate 2: <summary>
Reports: docs/superpowers/critic-reports/<SLUG>-gate{1,2}.md

## Tasks
$(bd list --epic $EPIC_ID --status closed | head -20)

🤖 Generated by /feature pipeline
EOF
)"
```

Do NOT push to remote. Print the merge SHA or PR URL and tell the user to push manually if desired.

---

## Phase 11: Master Plan update

Update `docs/features.md`: move the feature from "In progress" to "Shipped" with date:
```
- [x] [F-XXX] <slug> — <description> — shipped YYYY-MM-DD
```

```bash
git add docs/features.md
git commit -m "docs: feature shipped — <slug>"
```

Close the beads epic:
```bash
bd close $EPIC_ID --reason "Shipped — merge SHA <sha>"
```

---

## Phase 12: Final report (not numbered as a pipeline phase — just output)

```
✓ Feature shipped: <description>

Spec:    docs/superpowers/specs/<SLUG>.md
Plan:    docs/superpowers/plans/<SLUG>.md
Critic:  gate-1 (<summary>), gate-2 (<summary>)
Tasks:   <N> beads tasks closed
Diff:    <merge-sha or PR URL>
Tests:   <pass/fail summary>

Next: /feature "<next thing>" or git push (manual).
```

---

## Error handling summary

| Failure | Action |
|---|---|
| Master Plan unfilled | Stop, suggest `/init` |
| Brainstorm clarifying question | Surface to user, wait |
| Critic gate-1 Critical, user `address` | Re-run brainstorm with findings; max 2 retries |
| Critic gate-2 Critical, user `address` | Add tasks, re-loop TDD; max 2 cycles |
| TDD attempt loop > 3 | Stop, surface |
| Verify command non-zero | Stop, surface |
| Merge conflict | Stop, surface, do NOT auto-resolve |
| `gh` not installed when `pr` mode | Fall back to `merge` mode, warn user |

## Constraints

- This command should NEVER push to a remote.
- This command should NEVER skip critic gates silently.
- This command should NEVER claim done without Phase 9 verification passing.
- This command should NEVER update `docs/architecture.md` (only `/plan-improve` does that).
