---
description: Generate a requirements questionnaire for someone else's head — a client, domain expert, or stakeholder who holds knowledge you need. Interviews you only about the send (who + what must come back), then drafts a fill-in Markdown document. Answered questionnaires feed the next /feature's ground phase.
argument-hint: "<topic or decision that is blocked on someone else>"
---

# /questionnaire — extract requirements from someone else's head

**Input:** `$ARGUMENTS` (optional — the blocked topic; may be empty if the conversation already established it)

Use when a decision is blocked on knowledge that lives with one other person: a client, a domain expert, a colleague. Interviewing the user about the *subject* is pointless here — not knowing the subject is why the document is being written. So this command grills the user about the **send**, never the subject.

Question format and hygiene: `docs-meta/ELICITATION.md` (this command asks exactly two things, but each follows the ❓/➡️ format).

---

## Phase 1: The send (two exchanges, then stop asking)

Ask, in one round:

```
❓ 1. Who is this going to?
Their role, expertise, and relationship to you — this fixes the tone and how much context the document must carry (an outside client needs orienting; a teammate does not).
➡️ Recommended: <best guess from conversation context, if any>

❓ 2. What do you need back?
The concrete decisions or facts you cannot resolve alone. This becomes the checklist the finished document is measured against.
➡️ Recommended: <best guess from conversation context, if any>
```

Wait for both answers. Do NOT ask about the subject itself — if the command finds itself asking a third, subject-flavored question, it is off the rails.

---

## Phase 2: Draft the document

Generate `docs/requirements/questionnaire-<slug>.md` (`<slug>` = 3-5 words from the topic; create the directory if missing: `mkdir -p docs/requirements`).

Document shape (prose in the conversation's language; markers/IDs English — see `docs-meta/ELICITATION.md` "Artifact language"):

- **Purpose line** naming the decision riding on the answers, and a short context section written for a recipient who was never in this conversation.
- **Questions grouped under themed headings, most-important-first** — async means one pass may be all you get.
- **One idea per question**, never compound; an answer stub under each (`> Ответ:`); a *why this matters* line only where a question could be misread.
- **Explicit permission to answer "I don't know"** — a flagged uncertainty is useful; a confident guess that reads like a fact is not.
- **Closing catch-all:** anything we didn't ask that we should know?

Completeness check before saving: every item the user named in "what do you need back" must be traceable to at least one question. List the mapping to yourself; add questions for any gap.

---

## Phase 3: Save + commit

```bash
mkdir -p docs/requirements
# write the file, then:
git add docs/requirements/questionnaire-<slug>.md
git commit -m "docs: questionnaire for <recipient role> — <topic>"
```

Print:

```
✓ Questionnaire written: docs/requirements/questionnaire-<slug>.md
Send it (paste into email/Slack/ticket — delivery is yours), then drop the answered
file back into docs/requirements/. The next /feature or /improve ground phase reads
answered questionnaires automatically; answers become "User decisions" with provenance.
```

---

## Constraints

- Never ask about the subject — only the send (recipient + what must come back).
- One run = one document for one recipient. Three people holding three parts of the answer = three runs.
- This command does NOT send anything anywhere; it writes a local file.
- No git push (repo policy).
