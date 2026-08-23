---
id: F-011
slug: wb-scheme
status: shipped
created: 2026-05-02
supersedes:
superseded_by:
---
# F-011 — Well-balanced схема

## Functional requirements

### FR-01 Сохранение покоя
mid: 7c1f4a9e2b8d4f1aa30c65e7d9b1c204
status: active
Acceptance (EARS): Пока поверхность воды горизонтальна и скорость нулевая, солвер SHALL сохранять состояние покоя с невязкой не более 1e-14.
Source: spec 2026-05-02-wb-scheme — User decisions #3
verify: {method: Test, oracle: invariant, evidence: tests/wb_test.py::test_lake_at_rest}
code: {path: src/math/wb.cpp, symbol: WellBalanced::source_term, sha256: 9f2ac41d, verified_at: 2026-06-14}

### FR-02 Сухое дно
mid: b31e77aa0c9d4e5fa1220f6634bb9911
status: active
Acceptance (EARS): Если глубина в ячейке меньше 1e-8, то система SHALL обнулить скорость и сохранить массу.
Source: assumption (confirmed at playback 2026-05-02)
verify: {method: —, oracle: —, evidence: —}

## Non-functional requirements

### NFR-01 Невязка покоя
mid: 51aa9c30ee7b41d2b0c8d7e2f1a34456
status: changed
Threshold: <= 1e-14 невязка на рельефе произвольной формы · Proving command: pytest -k test_lake_at_rest · Counter-metric: время шага не хуже 4.0 мс

## Success criteria
| # | Criterion (with check-by) | Status | Evidence | Checked |
|---|---|---|---|---|
| SC-1 | Стоячая вода на реальном рельефе без паразитных течений | missed | скорости до 3 см/с | 2026-08-09 |

## Change history
| Date | Requirement (mid) | Change | Source |
|---|---|---|---|
| 2026-05-02 | FR-01 (7c1f4a9e) | created | spec wb-scheme |
| 2026-06-14 | NFR-01 (51aa9c30) | порог 1e-12 → 1e-14 | /improve tighten-wb |
