# Elicitation reference

This file is the **single source of truth** for how every pipeline command interviews the user. `/feature`, `/improve`, `/plan-improve`, `/init`, and `/questionnaire` reference it — they never restate it. Editing this file changes interviewing behavior project-wide.

Facts you can look up are never questions. Decisions are never made silently. That is the whole discipline; everything below is mechanics.

## The model: design tree, frontier, rounds

The subject of any interview is a **design tree**: decisions with decisions hanging off them. The **frontier** is the set of decisions whose prerequisites are all settled — the only questions that can honestly be asked yet. A **round** asks the whole frontier at once, and nothing else: two questions never share a round if one depends on the other.

**Question format (fixed):**

```
❓ 1. <Title of the decision>
<one or two sentences of body — what hinges on this>
➡️ Recommended: <option> — <one-line reason>
```

The user answers by number: "1 да, 2 второй вариант, 3 нет, потому что …". Options, where offered, are 2–5 mutually exclusive choices. After answers land, the frontier is recomputed — later rounds ask what the answers unblocked.

**Opt-out:** a user who prefers sequential questioning adds one line to their project `CLAUDE.md`: `When interviewing, ask one question at a time.` Honor it.

## Facts vs decisions

- **Facts are the agent's job.** Anything the repo, the docs, Context7, or a web search can answer is looked up, never asked. Asking the user a fact the environment holds is a hygiene violation (rule 5 below).
- **Decisions are the user's.** Every open decision is put to them in the round format and the agent **waits**. An agent that answers its own decision questions has broken this reference, not interpreted it liberally.
- **No question caps.** Some designs need three questions, some need thirty; the bound is by kind (decisions only), never by count. Steering ("wrap up", "accept your recommendations for the rest") is the user's control.

## Question hygiene (hard rules)

Before printing any question, silently check it against this lint; on any hit, rewrite it. Never show the check.

1. Not generic — it names this project's nouns, not "your users" in the abstract.
2. No unexplained jargon the user hasn't used first.
3. Not leading — it must not embed the expected answer.
4. Not compound — one idea per question; split "and/or" questions.
5. Not answerable from the environment (repo, docs, git history, web) — look it up instead.
6. Not already answered — reread the transcript and the coverage state first.
7. Not premature — its prerequisites are settled (it is actually on the frontier).
8. Concrete over abstract — "what happens when the matrix is singular?" beats "any edge cases?".
9. Carries a recommendation — every question ships a ➡️ line with a reasoned default.
10. Answerable briefly — by number, yes/no, or one sentence; never demands an essay.
11. Neutral on effort — never phrased to make "do nothing" the polite answer.
12. No false dichotomies — if a third option is plausible, list it or ask open-form.
13. In the user's language for prose (see "Artifact language" below).
14. Worth asking — the answer must be able to change what gets built; otherwise delete it.

## Micro-playback

A decision slot becomes **Confirmed** only after the user affirms a one-sentence paraphrase of their answer ("Т.е. допуск 1e-9 относительной ошибки против аналитического решения — верно?"). A hedged or contradictory affirmation reopens the slot with a clarification question. This catches misunderstandings twenty turns before the sign-off gate would.

## Surprise-chasing

When an answer introduces an entity, constraint, or scenario **not present in the coverage tree**: (a) log it under `## Surprises` in the coverage state file, (b) ask at least one follow-up about it before returning to the planned frontier. Following the script instead of the insight is the classic AI-interviewer failure.

## Forced NFR round

The final pre-playback round **must** iterate the non-functional dimensions of the coverage tree explicitly — tolerances and units, performance and memory envelopes, data scale, determinism/reproducibility, failure behavior. Measured LLM behavior: models elicit implicit non-functional requirements at a rate near zero when left to their own judgment. Never rely on the NFRs "coming up".

## Coverage state file

For any interview beyond a couple of rounds, keep state in `docs/superpowers/elicitation/<SLUG>-state.md`:

```markdown
# Elicitation state — <SLUG>

## Aspect: <e.g. Correctness & precision>
- [x] tolerance target — Confirmed: rel. error ≤ 1e-9 vs analytic oracle
- [ ] conditioning behavior — Unexplored
- [~] input validation — Rejected (out of scope, user 2026-08-18)

## Surprises
- <entity> — <follow-up asked, outcome>
```

Slot states: `[ ]` Unexplored · `[x]` Confirmed · `[~]` Rejected. The next question targets Unexplored slots; the playback gate reports the resolved fraction.

## Typed clarification debt

Open items never die in chat scrollback — they are written into the artifact itself:

- `[NEEDS CLARIFICATION: <specific question>]` — inline marker, **cap 3 per artifact**; priority when trimming: scope > security > UX > tech.
- `TBC: <what the user must confirm>` — a decision awaiting the user.
- `TBD: <what we must work out>` — a decision awaiting analysis.

Empty fields are forbidden — write a marker instead. Gates count open markers: the playback digest reports them, and the next interview round opens with the `TBC` items.

## Ceremony weight

One early stakes assessment sets `weight: light | standard | deep` (recorded in the spec frontmatter; default `standard`):

| weight | when | effect |
|---|---|---|
| `light` | small, low-stakes change | minimal spec; playback digest is 3 lines — **approval still required** |
| `standard` | normal feature work | full spec sections, full playback digest |
| `deep` | high-stakes / hard-to-reverse | full digest + an extra edge-case round before playback |

The weight question rides inside the first interview round (with a ➡️ recommendation) — it never costs a separate exchange.

## Artifact language

Prose in generated artifacts (specs, requirements, reports, questionnaires) is written in the **conversation's language**. IDs (`F-001`, `FR-012`), statuses, filenames, weight values, and greppable markers (`[NEEDS CLARIFICATION: …]`, `TBC:`, `TBD:`) are **always English** and never localized — tools grep for them.

## Termination gate

An interview is not finished when the frontier empties — it is finished when the user confirms the understanding is shared. The pipeline's spec **playback gate** is that confirmation: the original request authorizes planning only, and nothing gets built until the user approves the played-back digest.
