---
description: Deliberately retire or break a shipped feature — the non-additive path the normal pipeline cannot express. Impact scan, committed migration plan, code removal via the standard TDD loop, and a gate-2 critic that is TOLD the break is intended (it reviews the migration, not the regression).
argument-hint: "<feature id or slug to deprecate, and why>"
---

# /deprecate — intentional breaking change with a migration

`/improve`'s critic frames every behavior break as a regression. This command makes "we are deliberately breaking v1 behavior and migrating" expressible.

## Pre-flight

1. Target must exist: a `docs/requirements/F-*.md` with `status: shipped` matching `$ARGUMENTS`. Ambiguous → one ❓ with a ➡️ recommendation.
2. Run-state: same as `/feature` pre-flight step 3 (slug `YYYY-MM-DD-deprecate-<slug>`); `.phase` uses /feature-equivalent ids: impact scan=1, interview/playback=2–3.5, migration plan=4, removal TDD=7, gate-2=8, verify=9 (9b/9c inside), finish=10, close-out=11.

## Phase 1: Impact scan (facts — never questions)

- `docs/TRACEABILITY.md`: every run that touched this F-ID.
- Requirement chains: any file with `supersedes:`/`superseded_by:` pointing at it; FR/NFR mids other features' Source lines cite.
- Code: grep for the feature's `@relation(F-NNN/...)` markers and its public symbols across src; list every dependent call site.
- `docs/risks.md`: open risks scoped to this feature (deprecation may retire them — note which).

## Phase 2: Interview + playback (inherited, weight `deep` by default)

Frontier round: what replaces it (or nothing) / migration window / data migration needs / who must be told. Playback digest plays back the impact list verbatim + the migration outline; explicit approval appends `**Approved by user:**` to the migration plan. The original request authorizes planning only.

## Phase 3: Migration plan (committed artifact)

`docs/superpowers/plans/<SLUG>-migration.md`: data migration steps, API/interface transition (old → new, with the window), user-facing notice text, rollback point, and the dependent call sites from Phase 1 each mapped to an action. Committed at approval alongside the requirements-file update:

- Target requirements file: frontmatter `status: deprecated`, each removed FR/NFR block → `status: removed` (blocks stay — history is a chain), Change-history row marked **`BREAKING`** with the migration-plan path.
- `docs/features.md`: move the feature to Deprecated with date + migration link; Change-history row; `doc_version` bump.

## Phase 4: Remove via the standard loop

beads tasks per migration-plan step → TDD loop (tests updated FIRST to the new contract — deleting a test here is legitimate ONLY when the migration plan names it) → **critic gate-2 with the intended-break preamble:** "This run implements the approved migration plan at <path>; behavior breaks listed there are deliberate — review the MIGRATION (complete? dependents covered? rollback real?) and flag any break NOT listed in the plan as Critical." → verify (9/9b/9c as inherited) → finish (merge/PR, no push). When gate-2 dispatches fresh-context verification, its prompt MUST include the migration-plan path — a draft finding like "regression: deleted test Y" is disproved by the plan naming test Y, and the verifier cannot know that from the cited evidence alone.

## Phase 5: Close out

- TRACEABILITY row (action: deprecated); risks retired per Phase 1 → note for `/plan-improve` (type F).
- `/release` picks up the `BREAKING` row → next version is major (or minor while the product is 0.x) and the CHANGELOG carries the migration link.

## Constraints

- No removal without an approved, committed migration plan — even "nothing depends on it" gets a one-paragraph plan saying so.
- Deleting or weakening a test is legitimate only when the migration plan names that test.
- No push (repo policy).
