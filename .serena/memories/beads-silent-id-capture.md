Beads issue ID prefixes are project-derived (this repo's DB uses `ai-pipeline-plugin-*`), never a fixed `bd-` prefix. Scripts and command files must capture IDs via `bd create ... --silent` (prints only the issue ID, made for scripting) — never by grepping output for a `bd-` pattern.

Captured by senior-critic at gate-2 of the v0.3.1 patch branch on 2026-08-18.

Why stable: every command file that touches beads (feature/fix/improve/init) will recur into this; the wrong-prefix grep shipped in v0.3.0 and silently produced an empty EPIC_ID, no-oping `bd dep add`, `bd list --epic`, and `bd close`.