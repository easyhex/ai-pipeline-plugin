# Visual Verification — Design (v0.3.0)

**Date:** 2026-05-03
**Status:** Approved (brainstorm), pending implementation plan
**Targets plugin version:** v0.3.0 (minor bump from 0.2.0)

## Problem

The current pipeline (`/feature`, `/improve`, `/fix`) verifies code through tests, lint, type-check and build. None of these prove that a UI actually renders. A bug that breaks a route, throws on render, or fills the page with `console.error` will pass Phase 9 and ship.

## Goal

Add a sub-step inside Phase 9 (Verify) that, **for frontend projects**, drives a real browser via Playwright MCP, navigates to the URLs the spec lists, and stops the pipeline on visual regressions.

## Non-goals

- Replacing or weakening the existing Phase 9 checks (tests/lint/build still run unchanged).
- Cross-browser matrix testing — single Chromium via Playwright MCP only.
- Pixel-diff baselines — out of scope; this gate proves "renders without errors", not "matches a baseline".
- Mobile / responsive breakpoints — out of scope.
- Authenticated flows / fixtures — out of scope; the gate hits public routes only.

## Decisions made during brainstorm

| # | Decision | Choice |
|---|---|---|
| 1 | Browser tooling | **Playwright MCP** (Microsoft) |
| 2 | Enforcement | **Mandatory** if frontend detected (configurable via settings) |
| 3 | URL discovery | **From spec** — `## URLs to verify` section; fallback `[/]` |
| 4 | Dev server lifecycle | **Hybrid** — try existing `base_url`, else start `scripts.dev` ourselves |

## Architecture

A new visual sub-step lives **inside Phase 9** of `commands/feature.md`, `commands/improve.md`, `commands/fix.md`. It runs *after* the existing tests/lint/build pass, *before* Phase 10 (Finish). It is gated by:

1. Frontend detection (package.json deps OR root `index.html`).
2. `settings.pipeline.visual_verify.mode` ≠ `skip`.

Visual evidence is written to `docs/superpowers/visual-evidence/<slug>/`.

**Note on critic ordering.** Gate-2 critic runs at Phase 8, *before* Phase 9, so the critic does **not** see visual evidence on the initial `/feature` run that produces it. The visual sub-step is itself the gate for that run. The critic's visual-evidence read (component 9 below) applies to:

- `/improve` and `/fix` runs that touch a slug whose `docs/superpowers/visual-evidence/<slug>/` already exists,
- a future enhancement (out of scope here) that swaps Phase 8 ↔ Phase 9 ordering.

For the initial `/feature` run, the visual gate is enforced by Phase 9 itself, not by the critic.

## Components

### 1. Playwright MCP installation (`commands/init.md`)

Add to the prereq install block, alongside the existing `serena` install:

```bash
claude mcp add playwright -- npx '@playwright/mcp@latest'
```

If `claude mcp list` already shows `playwright` (any status), skip the add.

### 2. Frontend detector

Inline logic in Phase 9:

```bash
# Detected if any of these are true:
jq -e '.dependencies + .devDependencies | keys[] |
  test("^(react|vue|svelte|next|nuxt|@angular/core|solid-js|preact|@builder.io/qwik|astro)$")' \
  package.json >/dev/null 2>&1 \
  || test -f index.html
```

If false → skip visual sub-step entirely; Phase 9 ends after existing checks.

### 3. Settings schema (`assets/templates/settings.json`)

```json
{
  "pipeline": {
    "finish_mode": "merge",
    "visual_verify": {
      "mode": "required",
      "base_url": "http://localhost:3000",
      "dev_command": "auto",
      "dev_port_timeout_sec": 60,
      "fail_on_console_error": true
    }
  }
}
```

Field semantics:

- `mode`: `required` | `best_effort` | `skip`. Default `required`.
- `base_url`: where pipeline first probes for an already-running dev server.
- `dev_command`: `"auto"` reads `package.json` `scripts.dev` (else `scripts.start`). String overrides with explicit command.
- `dev_port_timeout_sec`: max wait for dev server to answer 200 OK after spawn.
- `fail_on_console_error`: in `required` mode, console errors stop the pipeline.

### 4. Dev server manager (inline in Phase 9)

```
1. GET base_url with 2s timeout.
   - 2xx/3xx → reuse, set DEV_PID=null.
   - else → resolve dev_command:
        if "auto": jq -r '.scripts.dev // .scripts.start' package.json
        else: use as-is
     spawn in background, capture DEV_PID.
     poll base_url every 1s until 2xx OR dev_port_timeout_sec elapsed.
     timeout → kill DEV_PID, fail (mode-dependent).
2. After all visual work done, if DEV_PID != null: kill DEV_PID.
   Trap kill on script exit so a crash doesn't leave processes behind.
```

### 5. URL extractor (inline in Phase 9)

```
spec_path = docs/superpowers/specs/<SLUG>.md
extract block under heading "## URLs to verify" (case-insensitive).
parse "- <path>" or "- <full-url>" lines.
if no section / no entries → URLS=["/"].
```

### 6. Browser driver (Playwright MCP calls)

For each URL:

```
mcp__playwright__browser_navigate({ url: base_url + path })
mcp__playwright__browser_snapshot()                     → save text to snapshots/<urlslug>.txt
mcp__playwright__browser_take_screenshot({ fullPage: true })
                                                          → save PNG to screenshots/<urlslug>.png
mcp__playwright__browser_console_messages()             → append to console.txt
```

(Tool names will be confirmed against the Playwright MCP currently installed during the writing-plans phase via Context7 / direct MCP introspection — design states intent, plan states exact API.)

### 7. Evidence store layout

```
docs/superpowers/visual-evidence/<slug>/
├── screenshots/
│   ├── _root.png
│   └── hello.png
├── snapshots/
│   ├── _root.txt
│   └── hello.txt
├── console.txt
└── summary.md
```

`summary.md` contains: URLs visited, HTTP status per URL, console error count, verdict (PASS/FAIL with reasons), timestamp.

URL slugs: `/` → `_root`; otherwise lowercase, strip query string, replace non-alphanum with `_`, collapse repeats, trim leading/trailing `_`. Examples: `/foo/bar` → `foo_bar`, `/users/[id]?tab=1` → `users_id`.

### 8. Pass/fail criteria

In `required` mode (`best_effort` only warns):

| Condition | Verdict |
|---|---|
| Any URL navigation returns 4xx/5xx | FAIL |
| Any URL emits a `console.error` (when `fail_on_console_error: true`) | FAIL |
| Screenshot file is < 1 KB or all-white/all-black (heuristic: median pixel variance) | FAIL |
| Playwright MCP unreachable / not installed | FAIL |
| Dev server fails to come up in `dev_port_timeout_sec` | FAIL |
| All checks pass | PASS, write `summary.md`, continue Phase 10 |

Pixel-variance check is a stretch goal — initial implementation can compare file size only.

### 9. Senior-critic update (`agents/senior-critic.md`)

At gate-2: if `docs/superpowers/visual-evidence/<slug>/summary.md` exists, the critic reads it and the snapshot text files. The critic does **not** open PNGs (those are for the human reviewer). The critic flags as **Important**:

- A `## URLs to verify` section in the spec that wasn't actually visited (drift between spec and run).
- Console errors logged but verdict marked PASS (mode mismatch).
- Snapshot text indicating empty `<main>` / `<body>` / "Application error" overlays.

### 10. Brainstorm hint

In Phase 2 of `feature.md`, `improve.md`: when the brainstorm spec is being assembled and the project is detected as frontend, the spec template includes:

```
## URLs to verify
<!-- One path per line. Pipeline will navigate to base_url + path in Phase 9.
     Empty section → only `/` is verified. -->
```

If the user doesn't fill it, fallback is `/`.

### 11. Documentation updates

- `assets/templates/CLAUDE.md` — note Playwright MCP as 6th context layer (after Serena memory).
- `assets/templates/PIPELINE.md` — add a row in the phase table for the visual sub-step.
- `README.md` and `README_RU.md` — bump feature list, mention visual gate.
- `docs/WORKFLOW_GUIDE_RU.md` — add a section explaining the new gate.

## Error handling matrix

| Failure | `required` | `best_effort` | `skip` |
|---|---|---|---|
| Playwright MCP not installed | STOP, "run `claude mcp add playwright …` or re-run `/init`" | warn, skip visual | (n/a — sub-step skipped) |
| Playwright MCP not responding | STOP | warn, skip | (n/a) |
| `package.json` `scripts.dev` missing AND `dev_command: "auto"` | STOP, "set `pipeline.visual_verify.dev_command` explicitly" | warn, skip | (n/a) |
| Dev server timeout | STOP, kill PID | warn, kill PID | (n/a) |
| URL 4xx/5xx | STOP after killing dev server | warn | (n/a) |
| Console errors (when `fail_on_console_error`) | STOP | warn | (n/a) |
| Screenshot file unreadable | STOP | warn | (n/a) |
| Spec missing | STOP — earlier phases require it; this is a bug | (same) | (n/a) |

In all stop paths: write `summary.md` with verdict=FAIL and reason, kill any DEV_PID we spawned.

## Versioning

`v0.2.0 → v0.3.0`. Bump in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Tag `v0.3.0` after smoke test.

## Smoke test

1. `mkdir /tmp/ai-pipeline-viz-$$ && cd $_`
2. `npm create vite@latest . -- --template react-ts && npm install`
3. `claude` → `/init "viz test"`
   - Verify `claude mcp list` shows `playwright`.
   - Verify `.claude/settings.json` contains `pipeline.visual_verify` block.
4. `/feature "add /hello route returning hello"` with spec containing `## URLs to verify\n- /hello`
   - Verify `docs/superpowers/visual-evidence/<slug>/screenshots/hello.png` created.
   - Verify pipeline reaches Phase 10.
5. Negative case: `/feature "add /broken route that throws on render"` with `mode: required`
   - Verify Phase 9 stops with FAIL, dev server killed, no merge.
6. `mode: best_effort` rerun of step 5 → verify warn but pipeline continues.
7. Cleanup: `rm -rf /tmp/ai-pipeline-viz-*`.

## Open questions (resolve in writing-plans phase)

- Exact Playwright MCP tool names and argument shapes (verify via Context7 / MCP introspection during plan).
- Pixel-variance heuristic for empty-screenshot detection — implement v1 with file-size only, leave variance check as a beads side-quest.
- How to surface evidence to a human reviewer in PR mode — add a markdown link block to the PR body? Pending discussion in plan.
