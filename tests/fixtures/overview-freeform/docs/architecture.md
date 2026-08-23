# BestCar Architecture

## Boundary

Маркетплейс подержанных авто: подбор, лиды, отчёты.

## Runtime Stack

| Layer | Choice | Why |
|---|---|---|
| Runtime | Node 22 | нативный fetch |
| DB | Postgres 16 | ссылочная целостность |

## Target Modules

`inventory`, `selection`, `leads`, `auth` and `wallet` are independent domain modules.
Routes validate transport concerns and call module use cases.

## Data Flow

Заявка приходит через API, валидируется на границе, попадает в lead-модуль.
