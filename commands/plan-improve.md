---
description: Refine the Master Plan (architecture / features / roadmap) without writing any feature code. Critic-reviewed.
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

Summarize the current state in 5 bullets. The user does not need to see this; you do.

## Phase 2: Determine change scope

The user request maps to one or more of these change types:
- **A** — adding a new feature to `features.md` (Planned section)
- **B** — reordering `roadmap.md`
- **C** — changing tech stack or architecture in `architecture.md`
- **D** — deprecating a shipped feature
- **E** — adding/removing a hard constraint

Identify which type(s). If unclear, ask the user **one** clarifying question.

## Phase 3: Clarifying questions (if needed)

If the request is ambiguous, ask up to 3 questions — but only if you genuinely cannot proceed without an answer. Skip if request is clear.

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

Same protocol as `/feature.md` Phase 8: parse the critic report's `## Memories to capture (suggested)` section. For each `` - `<slug>`: <summary> — <reason> `` line, call `mcp__serena__write_memory` (new) or append `## Update YYYY-MM-DD` (existing). Source line in the memory: `Captured by senior-critic at gate-1 of /plan-improve "$ARGUMENTS" on YYYY-MM-DD`.

If Serena MCP unavailable: warn, skip, continue.

Print: `Memories captured: <N> new, <M> updated, <P> skipped`.

If Critical findings exist, present them to the user and offer:
- `continue` — apply the change anyway (note in commit message)
- `address` — re-draft based on critic findings
- `override` — apply with written justification appended to the report

## Phase 6: Apply the change

Edit the affected `docs/*.md` files with the changes from Phase 4 (modified per critic if user chose `address`).

Verify the soft size budgets are not exceeded:
- `architecture.md` ≤ 300 lines
- `features.md` ≤ 500 lines
- `roadmap.md` ≤ 200 lines

If exceeded, warn the user and suggest splitting (don't auto-split).

## Phase 7: Commit

```bash
git add docs/architecture.md docs/features.md docs/roadmap.md
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
