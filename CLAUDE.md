# Contributor rules — ai-pipeline plugin

This file applies to anyone (human or AI agent) editing this **plugin repo**. It is NOT the per-project CLAUDE.md that ships to users — that one lives at `assets/templates/CLAUDE.md`.

## Before any change

1. Understand the layered structure:
   - `commands/` — 6 slash commands, auto-loaded
   - `agents/` — `senior-critic` subagent, auto-loaded
   - `assets/templates/` — files `/init` writes into user projects (do not auto-load)
   - `.claude-plugin/` — plugin manifest + marketplace entry
2. Templates in `assets/templates/` are user-facing. Changes to them ship to every new project after the next plugin update.

## Hard rules for plugin changes

1. **Templates and the per-project CLAUDE.md must stay consistent.** If you change `assets/templates/CLAUDE.md`'s rules, also check `assets/templates/PIPELINE.md` and the command files in `commands/` for drift.
2. **Lesson schema is canonical.** `assets/templates/LESSON_FORMAT.md` defines the schema. Any reference to lesson fields elsewhere (in `commands/` or `agents/senior-critic.md`) must match. Body length is a 3-sentence hard limit.
3. **Bumping the version**: any change to command behavior or template content requires a version bump in `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json`. Use semver (MAJOR.MINOR.PATCH).
4. **Test before publishing**: every change must be smoke-tested by running `/init` in `/tmp/test-<n>/` and confirming all per-project files are written correctly.
5. **Two READMEs**: `README.md` (English) and `README_RU.md` (Russian) must be updated together.
6. **No git push from inside Claude.** User pushes manually.
7. **Serena memory is the 5th context layer.** Any change to `commands/feature.md`, `commands/improve.md`, `commands/plan-improve.md`, or `agents/senior-critic.md` must keep the memory read/write logic intact (Phase 1 ground reads memories; gates auto-write suggested memories from the critic). Do not duplicate memory writes across multiple commands.

## Smoke test workflow

```bash
# Local install (for testing before publishing)
claude plugin marketplace add /Users/vladislav/Documents/00_CODE/ai-pipeline-plugin

# In a fresh terminal:
mkdir /tmp/ai-pipeline-smoke-$$
cd /tmp/ai-pipeline-smoke-$$
claude
> /init "test app"
# Verify:
> /help            # confirm 6 commands appear
> ls               # confirm CLAUDE.md, docs/, docs-meta/, .claude/, .gitignore present
```

After smoke test, clean up:
```bash
rm -rf /tmp/ai-pipeline-smoke-*
```

## Versioning policy

- 0.x → breaking changes between minor versions are OK
- 1.x → semver enforced (breaking changes only on major)
- Tag every release: `git tag v<version> && git push origin v<version>`
- v0.2.0 adds Serena memory integration; new prereq is `uv` + `serena-agent` (auto-installed by `/init`)

## What this plugin does NOT do

- Cross-agent compatibility (Claude Code only)
- Auto-install of system tools (`bd`, `gh`, `node`)
- Language-specific scaffolding (no `package.json` writing)
- Auto-push to remotes
