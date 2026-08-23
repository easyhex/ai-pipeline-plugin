# Architecture

---
doc_version: 3
last_changed: 2026-08-11
---

## 1. What this app is

Солвер уравнений мелкой воды на неструктурированной сетке для расчёта паводков.

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language(s) | C++20 | Шаблоны по размерности, нет GC в горячем цикле |
| Обвязка | Python 3.12 / pybind11 | Сценарии без пересборки ядра |
| Сетки | gmsh 4.13 | Покрывает все наши случаи |
| Ввод/вывод | HDF5 1.14 | Параллельная запись (ADR-005) |
| Testing | pytest + hypothesis | Property-оракулы |

## 3. Key modules / boundaries

- `io/` — чтение конфигов и сеток, запись дампов; depends on nothing
- `mesh/` — построение сетки и связность; depends on `io/`
- `math/` — римановы решатели, лимитеры; depends on nothing
- `bc/` — граничные условия; depends on `mesh/`
- `core/` — интегратор по времени, CFL; depends on `mesh/`, `math/`, `bc/`
- `post/` — инварианты и диагностика; depends on `core/`, `io/`
- `cli/` — сценарии прогонов; depends on `core/`, `post/`

## 4. Data flow

Конфиг и сетка входят через io, схема собирается в core, поля уходят в post и обратно на диск.

## 5. External services

| Service | Purpose | Auth method |
|---|---|---|
| S3 | хранение дампов | ключ в env |
