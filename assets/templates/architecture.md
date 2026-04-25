# Architecture

> **Template note:** `/init` fills this in based on the app description and clarifying questions. `/plan-improve` updates it. Do NOT edit manually inside Claude — go through `/plan-improve` so the change is reviewed by the critic.

**Status:** UNFILLED — run `/init "<app description>"` to populate.

---

## 1. What this app is

<one paragraph: the app's purpose, target user, and the single problem it solves>

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language(s) | <e.g. TypeScript> | <reason> |
| Framework | <e.g. Next.js 15> | <reason> |
| Database | <e.g. PostgreSQL via Prisma> | <reason> |
| Auth | <e.g. NextAuth> | <reason> |
| Hosting | <e.g. Vercel + Supabase> | <reason> |
| Testing | <e.g. Vitest + Playwright> | <reason> |

## 3. Key modules / boundaries

<bullet list of top-level modules, one line each: name, purpose, depends-on>

Example shape:
- `api/` — REST endpoints; depends on `db/`, `auth/`
- `db/` — schema + migrations; depends on nothing
- `auth/` — JWT verification; depends on `db/`
- `ui/` — React components; depends on `api/`

## 4. Data flow

<2-5 sentences describing how a typical request moves through the system>

## 5. External services

| Service | Purpose | Auth method |
|---|---|---|
| <e.g. Stripe> | <e.g. payments> | <e.g. API key in env> |

## 6. Hard architectural constraints

<bullet list of things that MUST be true — security, compliance, performance budgets. Empty is OK.>

---

**Soft size budget for this file:** 300 lines. If you exceed it, that's a signal the architecture is fragmenting — split a sub-system into its own document and link to it from here.
