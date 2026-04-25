---
description: Debug a bug end-to-end. Uses systematic-debugging instead of brainstorming. Always ends by writing a lesson file to .claude/lessons/.
argument-hint: "<bug description>"
---

# /fix — debug + auto-lesson

**Input:** `$ARGUMENTS` (the bug description — symptom or repro)

## Pre-flight

1. Master Plan must exist (same check as `/feature`).
2. Generate `$SLUG` as in `/feature`, but prefix with `fix-`: `YYYY-MM-DD-fix-<slug>`.
3. Announce: "Starting /fix pipeline for: <description>. Will debug, fix, then write a lesson file."

---

## Phase 1: Ground (debug-flavored)

Read:
- `docs/architecture.md`
- `docs/features.md` (which feature does this bug touch?)
- `.claude/lessons/` — pay extra attention; this bug may already have a lesson that was ignored.

If a lesson's `trigger:` matches this bug, surface it immediately to the user: "Lesson `<filename>` warned about this. Either the lesson wasn't applied or its `prevention:` is incomplete. Updating it may be appropriate after the fix."

---

## Phase 2: Systematic debugging

Invoke `superpowers:systematic-debugging`:

1. Reproduce the bug (write a failing test that captures the symptom)
2. Hypothesis (what's the most likely cause?)
3. Single-variable test of the hypothesis
4. Root cause identified
5. STOP after 3 failed hypotheses → step back, question architecture

The output of this phase: a confirmed root cause + a failing test that proves the bug.

Save the diagnosis as a brief markdown to:
```
docs/superpowers/specs/<SLUG>-diagnosis.md
```

---

## Phase 3: Critic gate-1 (diagnosis review)

Invoke `senior-critic` at gate 1 with the diagnosis as the "spec".

Critic asks: is this really the root cause, or just a symptom of a deeper issue? Are there other places this same bug exists? Are there missing tests for similar conditions?

If Critical findings on the diagnosis: address (re-debug) before fixing.

---

## Phase 4: Plan + bd-tasks (small)

For most bugs, the plan is 1-3 tasks:
- Fix the root cause
- Verify the failing test now passes
- Add regression test(s) for related conditions surfaced by critic

Create beads tasks via `bd create`.

---

## Phase 5: TDD loop

For each task: RED already exists from Phase 2; jump to GREEN. Then REFACTOR. Commit with `fix(<slug>): <task title>`.

If the bug touches multiple files, the worktree decision applies same as `/feature` (>3 tasks → worktree).

---

## Phase 6: Critic gate-2

Same as `/feature` Phase 8.

---

## Phase 7: Verify

Same as `/feature` Phase 9. Plus: explicitly run the test from Phase 2 to prove the bug is fixed.

---

## Phase 8: Finish

Same as `/feature` Phase 10 (merge/PR per `pipeline.finish_mode`).

---

## Phase 9: Lesson write (replaces master-plan-update)

Construct a lesson file from the debug session. Use the schema in `docs-meta/LESSON_FORMAT.md`.

Filename:
```
.claude/lessons/<SLUG>.md
```
(where SLUG is `YYYY-MM-DD-fix-<slug>` — but for the lesson, drop the `fix-` prefix to make the trigger more general)

Content (fill from the debug session):

```markdown
---
trigger: <derive from the affected files / domain — what kind of work brings this back?>
symptom: <one line, from Phase 1 description>
root_cause: <from Phase 2>
prevention: <one imperative rule — what should the agent do next time to avoid this?>
---

<2-3 sentences of context. What you tried, what surprised you, what to remember.>
```

Then:
```bash
git add .claude/lessons/<filename>
git commit -m "lesson: <one-line trigger>"
```

If a lesson already existed that matched this bug's trigger (surfaced in Phase 1), append `## Update YYYY-MM-DD` section to that lesson with the new prevention rule, instead of creating a new lesson.

---

## Phase 10: Final report

```
✓ Bug fixed: <description>

Diagnosis:    docs/superpowers/specs/<SLUG>-diagnosis.md
Critic:       gate-1 (<summary>), gate-2 (<summary>)
Tasks:        <N> beads tasks closed
Lesson:       .claude/lessons/<filename>
Diff:         <merge-sha or PR URL>

Lesson trigger: <trigger>
Lesson prevention: <prevention rule>

Next: /feature "<next thing>" or git push (manual).
```

---

## Constraints

- This command MUST end with a lesson written. If you can't formulate a lesson, the root cause wasn't deep enough — go back to Phase 2.
- This command does NOT update `docs/features.md` (bug fixes don't change features).
- This command does NOT update `docs/architecture.md` (use `/plan-improve` if architecture needs to change in response).
