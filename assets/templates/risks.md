# Risk register

> **Template note:** the 4th Master Plan file. Rows are appended AUTOMATICALLY whenever a critic-gate finding is `override`-d (the pipeline writes the row from the override reason) and manually via `/plan-improve`. Ground phases read this file; the critic receives it at BOTH gates and re-flags any `open` risk whose scope matches the current work. Only `/plan-improve` retires rows.

---
doc_version: 1
last_changed: UNSET
---

**Status:** empty — populated by gate overrides and `/plan-improve`.

## Open

| ID | Date | Source | Risk (what was accepted) | Reason (verbatim from override) | Review-by (condition or date) | Link |
|---|---|---|---|---|---|---|

## Retired

| ID | Retired | How it was resolved | Original row |
|---|---|---|---|

## Change history

| Date | Version | Change | Source |
|---|---|---|---|

---

**Row rules:** IDs are `R-NNN`, sequential, never reused. `Review-by` is a real condition ("before first production run", "when dataset > 1e6 rows") or a date — "someday" is not a condition. A risk row is never deleted, only moved to Retired. **Soft size budget:** 150 lines — if exceeded, the project is accepting more risk than it retires; that is a signal, not a formatting problem.
