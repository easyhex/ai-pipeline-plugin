# Mathematical model

> **Template note:** installed for compute project classes (numerical-library / simulation / data-pipeline). The mathematical ground truth of the project — what the code claims to compute. Owned by `/plan-improve` (like architecture.md); read in every ground phase; the gate-1 critic checks specs against it. Symbols used here MUST appear in `docs/glossary.md`.

---
doc_version: 1
last_changed: UNSET
---

**Status:** UNFILLED — populated by `/init` for compute classes, refined via `/plan-improve`.

## 1. Problem statement

<the mathematical formulation: equations, domains, boundary/initial conditions — LaTeX-in-markdown welcome>

## 2. Assumptions

<what the model assumes about inputs and the world — each one testable or explicitly untestable>

## 3. Invariants

<what must hold at all times: conservation laws, symmetries, monotonicity, bounds — these seed the property oracles (see docs-meta/NUMERICS_TESTING.md)>

## 4. Units & symbols

<unit system and key symbols — one line each, mirrored in docs/glossary.md>

## 5. Accuracy targets

| Quantity | Target (WITH units, abs/rel) | Against which oracle | Source NFR |
|---|---|---|---|

## 6. Known failure regimes

<where the method degrades or breaks: stiffness, ill-conditioning, singular inputs, domain boundaries — each regime either handled (say how) or declared out of scope (say where)>

## Change history

| Date | Version | Change | Source |
|---|---|---|---|

---

**Soft size budget:** 250 lines.
