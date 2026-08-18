# ADR format

Architecture Decision Records live in `docs/decisions/NNNN-<slug>.md` (NNNN = next free 4-digit number). They are committed, human-readable, and enforcement-shaped: each names what it governs and what it prevents, so the critic has something concrete to re-check.

**Three-gate test — write an ADR only when ALL three hold:**
1. Hard to reverse (or expensive to revisit).
2. Surprising without context (future-you would ask "why on earth…").
3. A real trade-off was made (something was given up).

Everything else is a Serena memory or nothing. Aim: ADRs stay rare and dense.

## Shape

```markdown
# NNNN — <decision title>

Date: YYYY-MM-DD · Status: accepted | superseded by NNNN
Source: <run slug / critic gate / manual>

## Context
<1-3 sentences: the forces that made this a decision>

## Decision
<1-2 sentences: what was decided>

## Consequences
<what got easier, what got harder, what debt was accepted>

## Binds
<the F/FR/NFR ids this decision governs — e.g. F-007/FR-01, F-007/NFR-02>

## Prevents
<the specific divergence this stops — e.g. "silently switching the solver family for speed">

## Rule
<one checkable constraint the critic can re-verify — e.g. "any solver change must re-run the NFR-02 tolerance suite">
```

**Who writes them:** the orchestrator, when the senior-critic marks a memory suggestion with `[decision]` at a gate (the Serena memory is still written as the agent-facing mirror); or the user/agent manually when a decision passes the three-gate test mid-work. One decision per file.
