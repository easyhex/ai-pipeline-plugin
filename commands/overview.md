---
description: Build docs/overview.html — one human-readable page showing the project's tech specs (ФТТ/НТТ) and structure. Derived from docs/ alone; regenerate, never edit.
argument-hint: "[--open]"
---

# /overview — visualize the specs and the structure

The Master Plan and the requirement files hold the truth, but nobody reads nine markdown files at once. This command projects them into a single self-contained HTML page: module map, stack, ФТТ/НТТ with their EARS wording and evidence, NFR thresholds and proving commands, success criteria, feature readiness, roadmap-by-status, and the open risk register.

**The page is derived.** It is regenerated, never hand-edited. Sources stay the truth.

## Phase 1: Pre-flight

1. `docs/` must exist. If not → STOP: "no `docs/` — run `/init` first."
2. `python3` must be on PATH. If not → STOP: "python3 required for /overview."
3. Master Plan check: if `docs/architecture.md` is missing or still carries `**Status:** UNFILLED`, say so in one line and continue — the page renders what exists and marks the rest as unfilled.

## Phase 2: Generate

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/pipeline/overview/generate.py" . -o docs/overview.html
```

The script reads, tolerating absence of any of them:

| Source | What it contributes |
|---|---|
| `docs/architecture.md` | §1 purpose, §2 stack, §3 modules + `depends on` (the graph), §4 data flow, §5 services |
| `docs/features.md` | feature inventory + status |
| `docs/roadmap.md` | Now / Next / Later / Explicitly NOT lanes |
| `docs/risks.md` | Open rows; a `Review-by` date in the past is flagged overdue |
| `docs/requirements/F-*.md` | ФТТ/НТТ: EARS wording, `mid`, `status`, `Source`, `verify`, `code`, thresholds, proving commands, success criteria |

Readiness stage per feature is derived, not asserted: `deprecated` → снята; `shipped` with a `met` success criterion → подтверждена; `shipped` → сделана; `in-progress` → в работе; `planned` with a requirements file → продумана; otherwise → идея. This is the same evidence-over-claim rule `/resume` uses.

## Phase 3: Report

Print the one-line summary the script emits (feature / module / ФТТ / НТТ / risk counts and the output path), then tell the user the file is at `docs/overview.html` and opens with a double click — no server, no network.

If `$ARGUMENTS` contains `--open`, additionally run `open docs/overview.html` (macOS) or `xdg-open docs/overview.html` (Linux), ignoring failure.

## Constraints

- **Read-only over sources.** The command writes exactly one file: `docs/overview.html`. It never edits `docs/` sources, never touches run-state, never runs the pipeline.
- **No new data sources.** Everything comes from `docs/`. Coverage reports, token accounting and any other external signal are deliberately out of scope.
- Safe at any time, including mid-run — it neither reads nor writes `docs/superpowers/runs/`.
- Commit `docs/overview.html` like any other doc artifact; it regenerates deterministically from the same sources.
