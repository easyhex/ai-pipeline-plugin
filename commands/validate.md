---
description: Validate shipped features against their declared success criteria with real-world outcome evidence. Records met/missed verdicts into the requirements files; missed criteria produce a roadmap-reprioritization proposal for /plan-improve. Closes the loop the pipeline otherwise leaves open at the reality end.
argument-hint: "[feature id or slug — optional; defaults to all due features]"
---

# /validate — falsify shipped guesses against reality

The pipeline's learning loop otherwise ingests only bugs — never "we built the wrong thing". This command asks reality.

## Phase 1: Collect due features

1. Candidates: `docs/requirements/F-*.md` with frontmatter `status: shipped` (narrow to `$ARGUMENTS` if given).
2. A feature is DUE when its `## Success criteria` section has any criterion with status `unchecked`, or a `met`/`missed` whose check-by condition has re-triggered (e.g. "re-check at 10× data scale").
3. Nothing due → report "Nothing to validate" and stop. A shipped feature with NO Success criteria section is itself a finding — list those ("shipped unfalsifiable") and suggest adding criteria via `/plan-improve`.

## Phase 2: Gather outcome evidence (frontier format)

Per due feature, one round per `docs-meta/ELICITATION.md`:

```
❓ 1. <criterion text> — met by <check-by condition>?
Evidence you can point at (a number, a dataset run, a user report, a log) beats impressions.
➡️ Recommended: <what the agent can pre-check itself — e.g. re-run the criterion's proving command NOW and show the result>
```

Facts first: any criterion with a machine-checkable form (a proving command, a dataset threshold) is RE-RUN by the agent before asking — the user confirms interpretation, not raw numbers. "I don't know yet" is a valid answer (criterion stays `unchecked` with a note).

## Phase 3: Record

For each criterion: set `met | missed | unchecked` with a one-line evidence note and date in the requirements file's `## Success criteria` section; append a Change-history row (`validated: N met / M missed`); bump nothing else — requirements text does not change here.

```bash
git add docs/requirements/
git commit -m "docs: validation — <F_IDs>: <N> met / <M> missed"
```

## Phase 4: Route the misses

`missed` criteria never die in the commit message:

1. Draft a reprioritization proposal — per missed criterion: what reality showed, which roadmap items it weakens/strengthens, a recommended reorder or a candidate `/deprecate`.
2. Print it and hand off: "Run `/plan-improve \"<one-line summary>\"` to apply — this command never edits the roadmap itself" (ownership rule).
3. If the miss looks like a defect rather than a wrong bet → suggest `/fix` instead.

## Report

```
✓ Validation: <K> features checked
Met: <N> · Missed: <M> · Unchecked: <U> (reasons noted)
Unfalsifiable (no criteria): <list or none>
Next: /plan-improve "<proposal>"  |  /fix "<defect>"  |  nothing due
```

## Constraints

- Never edits roadmap.md or architecture.md (that is /plan-improve's job).
- Never marks a criterion `met` without an evidence note — "feels fine" is `unchecked`.
- No push (repo policy).
