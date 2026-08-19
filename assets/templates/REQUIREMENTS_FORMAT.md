# Requirements file format

Living per-feature requirement files under `docs/requirements/F-NNN-<slug>.md`. Unlike dated specs (point-in-time inputs, never edited after approval), these files are the CURRENT truth about a feature's requirements and are amended over the feature's whole life.

- **Created** at `/feature` Phase 3.5, on playback approval, from the approved spec.
- **Amended** by `/improve` (see the update-vs-new rubric below).
- **Read** by every ground phase and both critic gates.
- **Referenced** globally as `F-007/FR-01`.

## Shape

```markdown
---
id: F-007
slug: <slug>
status: in_progress | shipped | deprecated
created: YYYY-MM-DD
supersedes: <F-id or empty>
superseded_by: <F-id or empty>
---
# F-007 — <title>

## Functional requirements

### FR-01 <title>
mid: <uuid — write once, NEVER edit; survives renames and renumbering>
status: active | changed | removed
Acceptance (EARS): When <trigger>, the <system> SHALL <response>.
Source: spec <slug> — User decisions #N | assumption (confirmed at playback YYYY-MM-DD)
verify: {method: Test | Analysis | Inspection | Review, oracle: <NUMERICS_TESTING taxonomy type or —>, evidence: <test id / doc path>}
code: {path: <file>, symbol: <function/class>, sha256: <of the symbol body>, verified_at: YYYY-MM-DD}   ← optional link

## Non-functional requirements

### NFR-01 <title>
mid: <uuid>
status: active
Threshold: <value WITH units, against what> · Proving command: <cmd> · Counter-metric: <must not degrade>

## Success criteria
| # | Criterion (with check-by) | Status | Evidence | Checked |
|---|---|---|---|---|
| SC-1 | <from the approved spec> | unchecked \| met \| missed | <one line> | YYYY-MM-DD |

`/validate` owns the Status/Evidence columns; `missed` rows route a reprioritization proposal to `/plan-improve`.

## Change history
| Date | Requirement (mid) | Change | Source |
|---|---|---|---|
| YYYY-MM-DD | FR-01 (<mid>) | created | spec <slug> |
```

## Verification method (v0.6)

`verify.method` — `Test | Analysis | Inspection | Review` — is **mandatory for compute project classes** (optional elsewhere): not everything is provable by test (algorithm stability is `Analysis` with a committed derivation; an architectural property is `Review`). Method-specific evidence obligations: `Test` → oracle type + test id; `Analysis` → path to the committed derivation doc; `Inspection`/`Review` → report link. The quant-verify gate refuses `verified` for a requirement whose declared evidence was not exercised.

## Code links (v0.6)

Numerical-kernel code carries docstring markers `@relation(F-NNN/FR-NN)`; the requirement's optional `code:` entry stores the symbol and a `sha256` of its body. The quant-verify gate recomputes hashes: a mismatch means the code changed since the requirement was last verified — the link becomes **suspect** (an Important finding to re-verify, never a silent pass and not a hard block). Coverage both ways: a public numerical function with no `@relation` marker, or a requirement with no linked code/test, is an advisory finding.

**mid rules:** generate with `uuidgen | tr A-F a-f` (or `python3 -c 'import uuid;print(uuid.uuid4().hex)'`); written once at creation; when a requirement is reworded or renumbered, the mid stays; when it is split, the closest descendant keeps the mid and the rest get new ones. `/release` diffs requirement files between tags BY MID to generate the "requirements changed" changelog section — editing a mid destroys that history.

## Update vs new (rubric for /improve)

Score the incoming change against the active file — amend in place when the answers lean yes, open a successor file (`supersedes:` chain) when they lean no:

1. Same intent as the existing feature?
2. More than half the scope overlaps?
3. Could the original NOT be called "done" without this change?
4. Does the update chain still tell one coherent story?

Amending: update the FR/NFR text, set `status: changed`, append a Change-history row. A removed requirement keeps its block with `status: removed` (history is a chain, not a pile). Deliberate behavior breaks are marked in the Change-history row as `BREAKING` — the gate-2 critic is told the break is intended.
