---
description: Modify existing behavior. Same auto pipeline as /feature, but ground phase emphasizes finding existing code paths to change. Strictly behavior change — does not add new features.
argument-hint: "<change to existing behavior>"
---

# /improve — modify existing behavior (full auto pipeline)

**Input:** `$ARGUMENTS` (description of the behavior change)

This command runs the **same 11-phase pipeline as `/feature`** with two differences:

1. **Phase 1 (ground)** emphasizes locating existing code paths to change (uses Grep + Read against current src/) and explicitly identifies the shipped feature(s) being modified by referencing `docs/features.md` Shipped section.

2. **Constraint:** This command MUST NOT add any new feature to `docs/features.md`. If during brainstorm or critic it becomes clear the work is actually new functionality, STOP and tell the user: "This work is a new feature, not an improvement. Run `/feature "<description>"` instead."

## Pre-flight

1. Master Plan must exist:
   - Run: `grep -q "UNFILLED" docs/architecture.md 2>/dev/null && echo unfilled || echo filled`
   - If `unfilled` → STOP. Print: "Run `/init "<app description>"` first."

2. At least one feature must be in `docs/features.md` Shipped section:
   - Run: `grep -A 100 "^## Shipped" docs/features.md | grep -q "^- \[x\]"`
   - If no shipped features → STOP. Print: "Nothing has shipped yet. Use `/feature` to build, not `/improve`."

3. Generate `$SLUG` as in `/feature`.

4. Announce: "Starting /improve pipeline for: <description>. Will modify existing behavior only — if work expands to new feature, will stop and redirect."

---

## Phase 1: Ground (improve-flavored)

In addition to the standard ground:
- Read `docs/features.md` Shipped section in full.
- Identify which shipped feature(s) this change targets. If unclear, ask the user one question.
- Run `Grep` for keywords from `$ARGUMENTS` across `src/` (or equivalent source dir) to locate the affected code paths.
- List the specific files that will be touched. If the list is empty, STOP and tell the user: "I can't locate existing code matching this description. Either the feature isn't shipped, or rephrase the request."

Then proceed with the standard ground steps (architecture.md, lessons, Context7).

---

## Phases 2-12: Same as `/feature.md`

All other phases run identically to `/feature`. Reference `.claude/commands/feature.md` for the full text — do not duplicate it here.

**Differences in specific phases:**

- **Phase 5 (Beads tasks):** Update `docs/features.md` should NOT add a new feature. Instead, append a note to the existing feature's line: `(behavior change in progress: <slug>)`.
- **Phase 8 (Critic gate-2):** The critic should be told this is an improvement; it pays special attention to "did this break the existing behavior the feature already shipped?" and "are there regression tests?"
- **Phase 11 (Master Plan update):** Do NOT move anything in `docs/features.md` (the feature was already Shipped). Just remove the `(behavior change in progress)` note. Optionally append a `- behavior changed YYYY-MM-DD: <slug>` sub-bullet under the feature.

---

## Branch naming

Use `improve/<slug>` instead of `feature/<slug>`.

## Commit prefixes

Use `refactor:` or `fix:` (not `feat:`) for commit messages during the TDD loop.

## Error handling

Same as `/feature`, plus:

| Failure | Action |
|---|---|
| Brainstorm reveals work is actually a new feature | STOP, tell user to run `/feature` instead |
| Cannot locate existing code matching description | STOP, ask user to rephrase or run `/feature` if it's actually new |
