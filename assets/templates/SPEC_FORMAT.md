# Spec format

Every spec the pipeline writes to `docs/superpowers/specs/` MUST follow this shape, so gates, the critic, and the requirements-file minting can parse it. Prose in the conversation's language; IDs, statuses, and markers always English (see `ELICITATION.md`).

## Required shape

```markdown
---
weight: light | standard | deep
---
# <SLUG> — <title>

## Goal
<one paragraph: what this feature is and why now>

## User decisions (verbatim)
<numbered, quoted from the interview and answered questionnaires — requirements with provenance>

## Assumptions (machine, unconfirmed)
<every material choice the user did not state>

## Out of scope (confirmed)
<what was explicitly refused>

## Functional requirements
### FR-01 <title>
<statement>
Acceptance (EARS): When <trigger>, the <system> SHALL <response>.
Source: User decisions #N | assumption

### FR-02 ...

## Non-functional requirements
| ID | Metric | Threshold (WITH units) | Proving command | Counter-metric (must not degrade) |
|---|---|---|---|---|
| NFR-01 | <e.g. relative error> | <e.g. ≤ 1e-9 vs analytic oracle> | <e.g. pytest -m oracle> | <e.g. runtime ≤ 2× current> |

## Mathematical approach   ← compute project classes: MANDATORY when the feature touches numeric computation
<the problem in mathematical terms; the chosen algorithm with a one-line stability/complexity suitability justification; known failure regimes (ill-conditioning, stiffness, domain boundaries); a validation plan naming real or reference data DISTINCT from the unit-test oracles>

## Interface contracts   ← compute classes: MANDATORY for every public numerical interface
<per interface: Preconditions (input domain — e.g. SPD matrix, sorted knots) / Postconditions (with tolerance) / Invariants preserved (conservation, symmetry, monotonicity)>

## Analogs considered
<per relevant row of docs/analysis/analogs.md: what they do, what we copy/avoid — or "none relevant">

## Success criteria
<observable, measurable, each with a check-by condition — how reality will falsify this feature after it ships. Math flavor: "residuals on dataset X below Y, re-checked at 10× scale". `/validate` asks for evidence against exactly these lines; a feature without them ships unfalsifiable.>

## Test plan / seams
<the invariants, tolerances, and tests that will prove the work — these are what the playback digest plays back as (e)>

## URLs to verify   ← frontend projects only
- /
```

At `light` weight every section stays mandatory but entries may be single lines. `[NEEDS CLARIFICATION: …]` (cap 3) and `TBC:`/`TBD:` markers replace empty fields — see `ELICITATION.md`.

The playback gate appends `**Approved by user:** YYYY-MM-DD (weight: <weight>)` on approval; the plan phase refuses to run without it.

## EARS — acceptance-criterion grammar

Every acceptance criterion is ONE of five patterns (mandatory at `standard`/`deep`; recommended at `light` — the critic flags violations at the mandatory weights):

| Pattern | Shape | Example (math flavor) |
|---|---|---|
| Ubiquitous | The <system> SHALL <response> | The solver SHALL accept CSR and dense inputs |
| Event-driven | **When** <trigger>, the <system> SHALL <response> | When cond(A) > 1e8, the solver SHALL switch to QR |
| State-driven | **While** <state>, the <system> SHALL <response> | While iterating, the residual SHALL decrease monotonically |
| Optional feature | **Where** <feature is present>, the <system> SHALL <response> | Where GPU is available, the kernel SHALL run batched |
| Unwanted behaviour | **If** <undesired condition>, **then** the <system> SHALL <response> | If the input contains NaN, then the API SHALL raise ValueError |

**WHAT/HOW litmus:** a criterion states WHAT is observable, never HOW it is implemented. "SHALL use LU decomposition" fails the litmus (implementation); "SHALL solve to rel. error ≤ 1e-9" passes. Every threshold carries units or an explicit reference (abs/rel, against what oracle).
