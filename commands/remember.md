---
description: Capture a project-specific fact to Serena memory. Used for stable knowledge (conventions, design decisions, domain facts) that doesn't fit lessons or master plan. Plain wrapper around Serena's write_memory MCP tool.
argument-hint: "<one-line fact to remember>"
---

# /remember — capture a fact to Serena memory

**Input:** `$ARGUMENTS` (the one-line fact to remember)

This is a 1-second utility. No critic, no plan, no tests.

---

## Phase 0: Pre-flight

Verify the Serena MCP server is reachable. Try a no-op call to `mcp__serena__list_memories`:

If the call fails with "MCP server not found" or similar, STOP. Print:

```
Serena MCP server is not running.
To enable /remember, the Serena MCP server must be registered:
  uv tool install -p 3.13 serena-agent@latest --prerelease=allow   # if not installed
  serena init                                                       # in this project
  claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd

Then restart Claude Code.
```

If the call succeeds, proceed.

---

## Phase 1: Derive a topic slug

From `$ARGUMENTS`, generate a 2-4 word kebab-case slug describing the topic (not the symptom). Examples:

- `$ARGUMENTS` = "auth uses JWT 1h TTL, refresh 30d, rotate on each use" → slug `auth-jwt-ttl-rotation`
- `$ARGUMENTS` = "we bill all users in EUR not USD" → slug `billing-currency-eur`
- `$ARGUMENTS` = "frontend uses snake_case in db cols, camelCase in TS" → slug `naming-snake-vs-camel`

If the topic is genuinely ambiguous, ask the user **one** clarifying question before proceeding. Otherwise pick the slug silently.

---

## Phase 2: Write (or update) the memory

Check if a memory with that slug already exists by calling `mcp__serena__list_memories`. The returned list has each memory's `name` field.

**If slug is NEW:**

Call `mcp__serena__write_memory` with:
```
name: <slug>
content: $ARGUMENTS
```

**If slug already exists:**

Read the existing memory via `mcp__serena__read_memory({ name: <slug> })`. Append the new fact as an `## Update YYYY-MM-DD` section, then write back via `mcp__serena__write_memory`:

```
<existing content>

## Update YYYY-MM-DD

$ARGUMENTS
```

(Use today's date in ISO format.)

---

## Phase 3: Confirm

Print:

```
✓ Wrote memory: <slug>
  Path: .serena/memories/<slug>.md
  Action: <created|appended-update>
```

---

## Error handling summary

| Failure | Action |
|---|---|
| Serena MCP unreachable | Stop with install instructions (Phase 0) |
| `mcp__serena__write_memory` fails | Print error verbatim, exit non-zero |
| User declines to clarify ambiguous slug | Ask once more; if still unclear, abort with "Couldn't derive a clear slug — try /remember with more specific phrasing" |

## Constraints

- This command MUST NOT run any phase from `/feature` or `/improve` (no critic, no TDD, no git).
- This command does NOT commit anything to git — Serena writes to `.serena/memories/` directly. The user can commit those files manually if they want them tracked.
- This command does NOT update `docs/architecture.md`, `docs/features.md`, or `.claude/lessons/`.
