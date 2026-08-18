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

## Non-functional requirements

### NFR-01 <title>
mid: <uuid>
status: active
Threshold: <value WITH units, against what> · Proving command: <cmd> · Counter-metric: <must not degrade>

## Change history
| Date | Requirement (mid) | Change | Source |
|---|---|---|---|
| YYYY-MM-DD | FR-01 (<mid>) | created | spec <slug> |
```

**mid rules:** generate with `uuidgen | tr A-F a-f` (or `python3 -c 'import uuid;print(uuid.uuid4().hex)'`); written once at creation; when a requirement is reworded or renumbered, the mid stays; when it is split, the closest descendant keeps the mid and the rest get new ones. `/release` diffs requirement files between tags BY MID to generate the "requirements changed" changelog section — editing a mid destroys that history.

## Update vs new (rubric for /improve)

Score the incoming change against the active file — amend in place when the answers lean yes, open a successor file (`supersedes:` chain) when they lean no:

1. Same intent as the existing feature?
2. More than half the scope overlaps?
3. Could the original NOT be called "done" without this change?
4. Does the update chain still tell one coherent story?

Amending: update the FR/NFR text, set `status: changed`, append a Change-history row. A removed requirement keeps its block with `status: removed` (history is a chain, not a pile). Deliberate behavior breaks are marked in the Change-history row as `BREAKING` — the gate-2 critic is told the break is intended.
