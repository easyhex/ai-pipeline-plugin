---
id: F-013
slug: adaptive-dt
status: in_progress
created: 2026-08-11
---
# F-013 — Адаптивный шаг

## Functional requirements

### FR-01 Снижение шага по Куранту
mid: c0ffee11223344556677889900aabbcc
status: active
Acceptance (EARS): Когда локальное число Куранта превышает 0.9, система SHALL уменьшить шаг до ближайшего вывода.
Source: spec 2026-08-11-adaptive-dt — User decisions #2
verify: {method: —, oracle: —, evidence: —}

## Non-functional requirements

### NFR-01 Накладные расходы
mid: dd00cc11bb22aa3399884477665500ff
status: active
Threshold: <= +5 % к общему времени прогона · Proving command: bench/adaptive.py · Counter-metric: —

## Success criteria
| # | Criterion (with check-by) | Status | Evidence | Checked |
|---|---|---|---|---|
| SC-1 | Прогон паводка ускоряется вдвое | unchecked | — | — |
