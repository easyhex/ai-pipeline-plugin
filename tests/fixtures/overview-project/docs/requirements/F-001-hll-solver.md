---
id: F-001
slug: hll-solver
status: shipped
created: 2026-02-14
---
# F-001 — Приближённый решатель Римана

## Functional requirements

### FR-01 Задача Сода
mid: 11aa22bb33cc44dd55ee66ff77008899
status: active
Acceptance (EARS): Когда на вход подан разрыв Сода, солвер SHALL воспроизвести положение ударной волны с погрешностью не более 1e-3.
Source: spec 2026-02-14-hll-solver — User decisions #1
verify: {method: Test, oracle: analytic, evidence: tests/riemann_test.py::test_sod}
code: {path: src/math/hll.cpp, symbol: HLL::flux, sha256: aa11bb22, verified_at: 2026-04-02}

## Non-functional requirements

### NFR-01 Детерминизм
mid: 99ff88ee77dd66cc55bb44aa33221100
status: active
Threshold: побитово равные дампы при одном сиде · Proving command: scripts/determinism.sh · Counter-metric: —

## Success criteria
| # | Criterion (with check-by) | Status | Evidence | Checked |
|---|---|---|---|---|
| SC-1 | Инженер воспроизводит эталон за < 5 мин | met | 3 из 3 инженеров | 2026-06-12 |
