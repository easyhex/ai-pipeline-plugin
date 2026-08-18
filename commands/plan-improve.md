---
description: Refine the Master Plan (architecture / features / roadmap / risks, plus glossary and analog analysis) without writing any feature code. Critic-reviewed.
argument-hint: "<change to make to the plan>"
---

# /plan-improve — refine the Master Plan

**Input:** `$ARGUMENTS` (description of the change to the plan)

## Pre-flight

- Run: `grep -q "UNFILLED" docs/architecture.md 2>/dev/null && echo unfilled || echo filled`
- If `unfilled` → STOP. Print: "Master Plan not initialized. Run `/init \"<app description>\"` first."

## Phase 1: Load current state

Read in full:
- `docs/architecture.md`
- `docs/features.md`
- `docs/roadmap.md`
- `docs/risks.md`
- `docs/glossary.md` and `docs/analysis/analogs.md` (when the request is type F/G, or when they inform the change)

Summarize the current state in 5 bullets. The user does not need to see this; you do.

## Phase 2: Determine change scope

The user request maps to one or more of these change types:
- **A** — adding a new feature to `features.md` (Planned section)
- **B** — reordering `roadmap.md`
- **C** — changing tech stack or architecture in `architecture.md`
- **D** — deprecating a shipped feature
- **E** — adding/removing a hard constraint
- **F** — retiring or updating a `docs/risks.md` row (move Open → Retired with resolution)
- **G** — updating `docs/analysis/analogs.md` or `docs/glossary.md`

Identify which type(s). If unclear, put the question to the user in the frontier-round format (❓ + ➡️ recommended answer).

## Phase 3: Clarification round (per docs-meta/ELICITATION.md)

Facts you can look up (current plan files, git history, code) are your job — never questions. Every open DECISION goes to the user as one numbered frontier round with recommended answers, and you wait. There is no question cap; the bound is by kind — decisions only. Skip the round only when no decisions are open.

## Phase 4: Draft the change

Write the proposed change as a unified diff (in your head — don't apply yet). For each file you'd touch:
- File: `docs/<file>.md`
- Specific section: `## <section>`
- Before/after of the affected lines

## Phase 5: Critic review (gate-1 equivalent)

Invoke the senior-critic agent with:
- Inputs: the proposed diff, current Master Plan files, all `.claude/lessons/`
- Gate: 1 (treat plan changes like spec changes)
- Slug: `plan-improve-YYYY-MM-DD-HHMM`

The critic returns its summary line. Save the report.

**Auto-write suggested memories (NEW):**

Same protocol as `/feature.md` Phase 8 — including the `[decision]` branch: parse the critic report's `## Memories to capture (suggested)` section. For each `` - `<slug>`: … `` or `` - [decision] `<slug>`: … `` line, call `mcp__serena__write_memory` (new) or append `## Update YYYY-MM-DD` (existing); `[decision]`-marked entries ALSO get a committed ADR in `docs/decisions/` per the `/feature` Phase 8 protocol. Source line in the memory: `Captured by senior-critic at gate-1 of /plan-improve "$ARGUMENTS" on YYYY-MM-DD`.

If Serena MCP unavailable: warn, skip, continue.

Print: `Memories captured: <N> new, <M> updated, <P> skipped`.

If Critical findings exist, present them to the user and offer:
- `continue` — apply the change anyway (note in commit message)
- `address` — re-draft based on critic findings
- `override` — apply with written justification appended to the report AND append a `docs/risks.md` row (same protocol as `/feature` gate-1: R-NNN, date, Source = plan-improve gate, finding, reason verbatim, review-by condition via one ❓, report link)

If Important-only (no Critical): present the Important findings (content, not just the count) and ask `continue / address`. Nice-to-have only: proceed. Decisions are synchronous — wait for the answer.

## Phase 6: Apply the change

Edit the affected `docs/*.md` files with the changes from Phase 4 (modified per critic if user chose `address`).

While applying: remove the `(proposed — unconfirmed)` suffix from any Master Plan line the user confirms or reworks in this run — this is the command that clears the tags `/init` leaves on unreviewed machine proposals.

In every versioned doc modified (`architecture.md`, `features.md`, `roadmap.md`, `risks.md`, and on type-G changes `glossary.md` / `analogs.md`): bump `doc_version` by 1, set `last_changed`, and append a `## Change history` row (date | version | one-line change | critic report path).

Verify the soft size budgets are not exceeded:
- `architecture.md` ≤ 300 lines
- `features.md` ≤ 500 lines
- `roadmap.md` ≤ 200 lines

If exceeded, warn the user and suggest splitting (don't auto-split).

## Phase 7: Commit

```bash
git add docs/architecture.md docs/features.md docs/roadmap.md docs/risks.md docs/glossary.md docs/analysis/analogs.md 2>/dev/null
git commit -m "docs: plan-improve — <one-line summary of change>

Critic report: <path-to-report>"
```

## Phase 8: Report

Print:
```
✓ Master Plan updated.

Files changed:
  - docs/<file>.md (<+N -M> lines)
  ...

Critic gate-1: <N> Critical / <M> Important / <P> Nice-to-have
Report: docs/superpowers/critic-reports/<filename>

Next: /feature "<something from the updated plan>"
```

## Error handling

| Failure | Action |
|---|---|
| Master Plan not initialized | Stop, suggest `/init` |
| Critic returns Critical findings, user picks `address` | Re-run Phase 4 with critic findings as input; loop max 3 times |
| Size budget exceeded | Warn but apply; suggest manual split |
| Git not in a repo | Skip commit, warn user |
