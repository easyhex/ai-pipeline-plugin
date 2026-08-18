# Features

> **Template note:** `/init` populates the initial planned features. `/feature` and `/improve` update this file (move feature from Planned → Shipped) at their final phase. `/plan-improve` adds new features to Planned.

**Format per feature (one line each):**
`- [ID] <slug> — <one-line description> — <status: planned|in-progress|shipped|deprecated>`

Shipped features gain a version stamp from `/release`: `— shipped YYYY-MM-DD in vX.Y.Z`. Every shipped feature has a living requirements file at `docs/requirements/<ID>-<slug>.md`.

---
doc_version: 1
last_changed: UNSET
---

## Planned

- [ ] <none yet — populated by /init>

## In progress

- [ ] <none yet — moved here automatically when a /feature run starts>

## Shipped

- [ ] <none yet — moved here automatically by the pipeline's master-plan-update phase>

## Deprecated

- [ ] <none yet — manual move when removing a feature>

---

## Change history

| Date | Version | Change | Source |
|---|---|---|---|

---

**Soft size budget for this file:** 500 lines. If exceeded, archive deprecated entries to `docs/features-archive.md` and link from here.
