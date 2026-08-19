---
description: Resume an interrupted pipeline run. Derives the true position from artifact existence (spec → approval → plan → tasks → reports → evidence → merge), reconciles it with the run-state cache, and continues from the derived phase. Run-state never lies its way past a missing artifact.
argument-hint: "[slug — optional; defaults to the active run]"
---

# /resume — continue an interrupted pipeline run

A session death, /clear, or compaction mid-run leaves artifacts on disk and a cache in `docs/superpowers/runs/current.json`. This command reconstructs the position and continues. **Files are the truth; the cache is a hint.**

## Phase 1: Locate the run

1. `SLUG` = `$ARGUMENTS` if given, else `.slug` from `docs/superpowers/runs/current.json`, else the newest spec under `docs/superpowers/specs/`. Nothing found → STOP: "no run to resume."
2. Read the cache (`docs/superpowers/runs/current.json`) if present — note its `.phase`, `.f_id`, `.branch`, but do not trust it yet. Read `precompact-snapshot.json` and `precompact-ledger-tail.jsonl` if present (context from before a compaction).

## Phase 2: Derive the true phase from artifacts

Walk the artifact DAG **top-down and resume at the FIRST UNSATISFIED row** (never "highest satisfied": after a gate-2 `address` loop the gate-2 report exists while Phase-7 tasks are reopened — the open tasks win):

| Evidence on disk | Phase completed |
|---|---|
| `docs/superpowers/specs/<SLUG>.md` exists (or `-diagnosis.md` for fix runs) | 2 (interview + spec) |
| gate-1 report in `docs/superpowers/critic-reports/` | 3 |
| spec contains `**Approved by user:**` AND `docs/requirements/F-*-<slug>.md` exists (fix runs: the diagnosis's `**Approved by user:**` line alone — no requirements file exists for a bug fix) | 3.5 |
| `docs/superpowers/plans/<SLUG>.md` exists | 4 |
| beads epic + tasks exist (`bd list` matching the feature) | 5 |
| the work branch exists — `feature/<slug>` (also for /fix runs, which inherit the prefix) or `improve/<slug>` (improve.md declares its own) | 6 |
| `bd ready` shows no open tasks for the epic | 7 |
| gate-2 report exists | 8 |
| `visual-evidence/<SLUG>/verdict.json` AND `quant-evidence/<SLUG>/verdict.json` exist with `status` pass/verified/skipped | 9/9b/9c (a `failed`/`partial` blocking verdict means resume INTO the gate's address flow, not past it) |
| merge commit on main mentioning `<slug>` | 10 |

Disagreement with the cache → the artifacts win; say so in one line.

## Phase 3: Reconcile side state

- Orphaned worktree/branch for the slug → reuse it (never create a second).
- Claimed-but-open beads tasks (`bd list --status in_progress`) → keep claims.
- Stale dev-server pid (`docs/superpowers/runs/dev-server.pid`) → kill + remove.
- No `current.json` but artifacts mid-flight → recreate the cache from the derived state.

## Phase 4: Confirm and continue

Print a 3-line playback: `run <SLUG> — derived phase <N> (<what proves it>). Continue from phase <N+1>? [y/n]`. On `y`: update `current.json` and continue executing the `/feature` phase definitions from that point (or `/fix`'s when the slug is a fix run). On `n`: leave everything as is; suggest deleting `current.json` to abandon.

## Constraints

- Never re-mints an F-ID: if `docs/requirements/` has the slug's file, its F-ID is THE F-ID.
- Never re-runs the playback gate if the spec carries `**Approved by user:**` — approval survives the crash.
- No push (repo policy).
