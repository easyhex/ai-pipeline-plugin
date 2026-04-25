---
description: Manually record a lesson learned. Used rarely (for things not coming out of /fix). Prompts for trigger / symptom / root_cause / prevention.
argument-hint: "[optional one-line context]"
---

# /lesson — manually record a lesson

**Input:** `$ARGUMENTS` (optional one-line context to seed the lesson)

Most lessons are written automatically by `/fix`. Use this command only when you want to capture something that wasn't a debugging session — e.g. a near-miss, a code review insight, a one-off realization from manual exploration.

## Phase 1: Prompt for fields

Ask the user **four questions in sequence** (one per message), referring to `docs-meta/LESSON_FORMAT.md` for guidance:

1. **trigger:** "When does this lesson apply? (one phrase the agent can match against future task descriptions or file paths)"
2. **symptom:** "What did you observe? (one line, past tense)"
3. **root_cause:** "What was the actual reason? (not the symptom — the underlying cause)"
4. **prevention:** "What's the imperative rule that prevents this? (start with a verb)"

Then:

5. **context:** "2-3 sentences of context for future-you to recognize the situation. Hard limit 3 sentences."

If `$ARGUMENTS` is provided, use it as a starting hint when asking the questions.

## Phase 2: Validate against schema

Check the answers against `docs-meta/LESSON_FORMAT.md`:
- `trigger` not too broad ("bugs", "code") and not too narrow (specific commit SHAs)
- `prevention` starts with a verb
- `root_cause` is a cause, not a symptom
- Body ≤ 3 sentences (per `LESSON_FORMAT.md` hard limit)

If any fail, push back: "Your `trigger:` is too broad — fires on every task. Can you narrow it?"

## Phase 3: Generate filename

Format: `YYYY-MM-DD-<3-6-word-topic-slug>.md`

The slug should describe the **topic**, not the symptom. Derive from the `trigger` field.

## Phase 4: Write the file

Save to `.claude/lessons/<filename>`.

## Phase 5: Commit

```bash
git add .claude/lessons/<filename>
git commit -m "lesson: <one-line trigger>"
```

## Phase 6: Report

```
✓ Lesson recorded.

File:       .claude/lessons/<filename>
Trigger:    <trigger>
Prevention: <prevention>

Total lessons: <count>
```

## Error handling

| Failure | Action |
|---|---|
| User abandons mid-questions | Discard partial input; print: "Lesson not recorded." |
| Field validation fails | Re-ask the failing field with explanation |
| File would conflict with existing lesson on same date+slug | Add suffix: `-2`, `-3`, etc. |
