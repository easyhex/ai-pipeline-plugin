---
description: Modify existing behavior. Same auto pipeline as /feature, but ground phase emphasizes finding existing code paths to change. Strictly behavior change — does not add new features.
argument-hint: "<change to existing behavior>"
---

# /improve — modify existing behavior (full auto pipeline)

**Input:** `$ARGUMENTS` (description of the behavior change)

This command runs the **same pipeline as `/feature`** (all phases, including the Phase 3.5 playback gate) with two differences:

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
- Identify which shipped feature(s) this change targets. If unclear, ask as a numbered question with a ➡️ recommended answer (per `docs-meta/ELICITATION.md`).
- Read the target feature's living requirements file `docs/requirements/F-*.md` in full — it is the current truth this change amends.
- Apply the **update-vs-new rubric** from `docs-meta/REQUIREMENTS_FORMAT.md` (same intent? >50% overlap? original not "done" without this? coherent story?) to DECIDE the path — amend vs successor. The actual file changes happen at Phase 3.5 on approval (see the mint delta below). An intended behavior break is marked `BREAKING` in the Change-history row, and the gate-2 critic is told the break is deliberate (it reviews the migration, not the regression).
- Run `Grep` for keywords from `$ARGUMENTS` across `src/` (or equivalent source dir) to locate the affected code paths.
- List the specific files that will be touched. If the list is empty, STOP and tell the user: "I can't locate existing code matching this description. Either the feature isn't shipped, or rephrase the request."

Then proceed with the standard ground steps (architecture.md, lessons, Context7).

**Memory grounding (NEW):** Same as `/feature.md` Phase 1 — call `mcp__serena__list_memories` and `mcp__serena__read_memory` for slug matches. Add `Memory grounding: N memories loaded` line to the internal summary. If Serena MCP not running, skip with note `Memory grounding: skipped (Serena unavailable)`.

---

## Phases 2-12: Same as `/feature.md`

All other phases run identically to `/feature`. Reference the `ai-pipeline:feature` command text for the full phase definitions (it ships with this plugin and is loaded alongside this command — it is NOT a file in the user's project). Do not duplicate it here.

**Differences in specific phases:**

- **Phase 3.5 (Playback gate) — MINT DELTA, read carefully:**
  - **Amend path** (the update-vs-new rubric said amend): do NOT mint — no new F-ID, no new requirements file. The digest plays back the amended FR/NFR set of the EXISTING `docs/requirements/F-*.md`. On approval: apply the amendment to that file NOW (amended blocks get `status: changed`, `BREAKING` rows where intended, a Change-history row with this slug; mids never change), then commit the spec + amended file (`docs(spec): approved — <slug> (amends <F_ID>)`). Amending before gate-2 is what lets the critic's requirements-drift check compare the diff against current truth instead of firing on every improvement.
  - **Successor path** (rubric said new): mint per `/feature`'s rule; the successor file carries `supersedes: <old F_ID>`, the old file gets `superseded_by:`; in `docs/features.md` do NOT add a feature line — append a sub-bullet under the existing feature: `— requirements superseded by <new F_ID> (YYYY-MM-DD)`.
- **Phase 5 (Beads tasks):** Update `docs/features.md` should NOT add a new feature. Instead, append a note to the existing feature's line: `(behavior change in progress: <slug>)`.
- **Phase 8 (Critic gate-2):** The critic should be told this is an improvement; it pays special attention to "did this break the existing behavior the feature already shipped?" and "are there regression tests?"
- **Phase 9 (Verify, including 9b visual):** Inherited from `/feature` Phase 9 — visual sub-step runs for frontend projects. The brainstorm in Phase 2 must include `## URLs to verify` listing the affected paths (the changed routes plus any cross-impacted views). For an improvement that doesn't change any URL, list at least `/`.
- **Phase 11 (Master Plan update):** Do NOT move anything in `docs/features.md` (the feature was already Shipped). Remove the `(behavior change in progress)` note and optionally append a `- behavior changed YYYY-MM-DD: <slug>` sub-bullet. The requirements amendment already happened at Phase 3.5 — here only append the TRACEABILITY.md row as in `/feature` (and, on the successor path, flip the successor file to `status: shipped`).
- **Memory hooks**: Same as `/feature.md` — Phase 1 reads relevant Serena memories; Phase 8 auto-writes critic-suggested memories.

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
