---
description: Build new functionality end-to-end. Full automatic pipeline (ground → brainstorm → critic → plan → TDD → critic → verify → finish). User intervenes only on real clarifying questions or Critical critic findings.
argument-hint: "<feature description>"
---

# /feature — build new functionality (full auto pipeline)

**Input:** `$ARGUMENTS` (the feature description)

## Pre-flight

1. **Master Plan must exist:**
   - Run: `grep -q "UNFILLED" docs/architecture.md 2>/dev/null && echo unfilled || echo filled`
   - If `unfilled` → STOP. Print: "Run `/init \"<app description>\"` first."

2. **Generate slug:**
   - Take first 4-6 meaningful words from `$ARGUMENTS`
   - Convert to lowercase, hyphenate
   - Format: `YYYY-MM-DD-<slug>` (use today's date)
   - Save as `$SLUG` for use in filenames throughout

3. **Announce intent:**
   - Tell the user: "Starting /feature pipeline for: <description>. Slug: <SLUG>. I'll proceed automatically through 11 phases. I'll only stop for real clarifying questions or Critical critic findings."

---

## Phase 1: Ground

Read in full:
- `docs/architecture.md`
- `docs/features.md`
- `docs/roadmap.md`
- Every file under `.claude/lessons/`

Detect libraries from package manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, etc.). For each detected library that is *plausibly relevant* to this feature, query Context7:

```
mcp__plugin_context7-plugin_context7__resolve-library-id { libraryName: "<lib>" }
mcp__plugin_context7-plugin_context7__query-docs { id: "<resolved>", topic: "<topic relevant to feature>" }
```

Produce a 5-10 bullet **ground summary** (internal — not shown to user unless asked):
- Architecture context (where this feature fits)
- Existing features it interacts with
- Roadmap position
- Lessons that match this feature's domain (cite filenames)
- Library-specific gotchas from Context7
- Open questions for brainstorm

---

## Phase 2: Brainstorm

Invoke `superpowers:brainstorming` with:
- The user's feature description
- The ground summary as context

The brainstorming skill produces a spec. Save it to:
```
docs/superpowers/specs/<SLUG>.md
```

If the brainstorm has a real clarifying question (not stylistic), ask the user. Wait for answer. Otherwise proceed silently.

---

## Phase 3: Critic gate-1

Invoke the `senior-critic` subagent (defined in `.claude/agents/senior-critic.md`):

```
Use the senior-critic subagent to review this spec at gate 1.
Inputs:
  - Spec: docs/superpowers/specs/<SLUG>.md
  - docs/architecture.md, docs/features.md, docs/roadmap.md
  - All files under .claude/lessons/
  - Original user request: "<$ARGUMENTS>"
Slug: <SLUG>
Gate: 1
```

The critic saves a report and returns a one-line summary like:
`critic gate 1: 0 Critical / 2 Important / 1 Nice-to-have. Report: docs/superpowers/critic-reports/<SLUG>-gate1.md`

**Decision:**
- If Critical > 0: present summary to user, ask `continue / address / override`. Default to `address` if user does nothing within 1 message exchange.
  - `address` → re-run Phase 2 with critic findings as additional input. Max 2 retries; if still Critical, force user decision.
  - `override` → user must provide a written reason; append to the report file.
  - `continue` → proceed.
- If Critical == 0: proceed silently. Mention only the one-line summary.

---

## Phase 4: Plan

Invoke `superpowers:writing-plans` on the spec at `docs/superpowers/specs/<SLUG>.md`. Save the plan to:
```
docs/superpowers/plans/<SLUG>.md
```

---

## Phase 5: Beads tasks

For each task in the plan:
```bash
bd create -t task "<task title from plan>" --description "<task description>"
```

Capture the IDs. For sequential tasks (Task N depends on Task N-1):
```bash
bd dep add <task-N-id> <task-N-1-id> --type blocks
```

Create a parent epic for the feature and add `parent-child` deps from each task to the epic:
```bash
EPIC_ID=$(bd create -t epic "<feature description>" | grep -oE 'bd-[0-9]+')
bd dep add <task-id> $EPIC_ID --type parent-child
```

Update `docs/features.md`: move/add the feature to "In progress" with the epic ID and slug.

---

## Phase 6: Worktree (conditional)

If the plan has > 3 sub-tasks, invoke `superpowers:using-git-worktrees`. This creates a worktree on a branch named `feature/<slug>`.

If ≤ 3 sub-tasks, work directly on a feature branch:
```bash
git checkout -b feature/<slug>
```

---

## Phase 7: TDD loop

Loop until `bd ready` returns no tasks blocked-by this epic:

```
For each ready task:
  - bd update <id> --claim
  - Invoke superpowers:test-driven-development for this task
    (RED → verify-fail → GREEN → verify-pass → REFACTOR)
  - After GREEN: git add -A && git commit -m "feat(<slug>): <task title>"
  - bd close <id> --reason "Done — see commit <sha>"
```

**Stop conditions:**
- 3 failed RED→GREEN attempts on a single task → stop, surface to user
- Test that should fail doesn't fail → stop (test is broken)
- Verification command fails → stop

---

## Phase 8: Critic gate-2

Invoke the `senior-critic` subagent at gate 2:

```
Use the senior-critic subagent to review at gate 2.
Inputs:
  - Diff: git diff main..HEAD (or git diff main..feature/<slug> if in worktree)
  - Spec: docs/superpowers/specs/<SLUG>.md
  - docs/architecture.md, docs/features.md
  - All files under .claude/lessons/
Slug: <SLUG>
Gate: 2
```

Critic saves report, returns one-line summary.

**Decision:**
- If Critical > 0: present to user, ask `continue / address / override`. Default `address`.
  - `address` → for each Critical/Important finding, run `bd create` to add a new task, then loop back to Phase 7 for those tasks. Max 2 cycles.
  - `override` → require written reason in report.
  - `continue` → proceed.
- If Critical == 0: proceed.

---

## Phase 9: Verify

Invoke `superpowers:verification-before-completion`. Identify and run the proving command(s) for this feature:
- Test suite: `<project's test command>`
- Lint: `<lint command if configured>`
- Type check: `<typecheck command if configured>`
- Build: `<build command if configured>`

For each: run fresh, read full output, capture exit code. If any fail → STOP, surface output, do not proceed.

---

## Phase 10: Finish

Read `.claude/settings.json`'s `pipeline.finish_mode`. Default `merge`.

**If `merge`:**
```bash
git checkout main
git merge --no-ff feature/<slug> -m "feat: <feature description> (merged from feature/<slug>)"
git branch -d feature/<slug>
# If worktree was used:
git worktree remove ../<worktree-dir>
```

**If `pr`:**
```bash
gh pr create \
  --title "feat: <feature description>" \
  --body "$(cat <<EOF
## Summary
<one paragraph from spec>

## Critic review
Gate 1: <summary>
Gate 2: <summary>
Reports: docs/superpowers/critic-reports/<SLUG>-gate{1,2}.md

## Tasks
$(bd list --epic $EPIC_ID --status closed | head -20)

🤖 Generated by /feature pipeline
EOF
)"
```

Do NOT push to remote. Print the merge SHA or PR URL and tell the user to push manually if desired.

---

## Phase 11: Master Plan update

Update `docs/features.md`: move the feature from "In progress" to "Shipped" with date:
```
- [x] [F-XXX] <slug> — <description> — shipped YYYY-MM-DD
```

```bash
git add docs/features.md
git commit -m "docs: feature shipped — <slug>"
```

Close the beads epic:
```bash
bd close $EPIC_ID --reason "Shipped — merge SHA <sha>"
```

---

## Phase 12: Final report (not numbered as a pipeline phase — just output)

```
✓ Feature shipped: <description>

Spec:    docs/superpowers/specs/<SLUG>.md
Plan:    docs/superpowers/plans/<SLUG>.md
Critic:  gate-1 (<summary>), gate-2 (<summary>)
Tasks:   <N> beads tasks closed
Diff:    <merge-sha or PR URL>
Tests:   <pass/fail summary>

Next: /feature "<next thing>" or git push (manual).
```

---

## Error handling summary

| Failure | Action |
|---|---|
| Master Plan unfilled | Stop, suggest `/init` |
| Brainstorm clarifying question | Surface to user, wait |
| Critic gate-1 Critical, user `address` | Re-run brainstorm with findings; max 2 retries |
| Critic gate-2 Critical, user `address` | Add tasks, re-loop TDD; max 2 cycles |
| TDD attempt loop > 3 | Stop, surface |
| Verify command non-zero | Stop, surface |
| Merge conflict | Stop, surface, do NOT auto-resolve |
| `gh` not installed when `pr` mode | Fall back to `merge` mode, warn user |

## Constraints

- This command should NEVER push to a remote.
- This command should NEVER skip critic gates silently.
- This command should NEVER claim done without Phase 9 verification passing.
- This command should NEVER update `docs/architecture.md` (only `/plan-improve` does that).
