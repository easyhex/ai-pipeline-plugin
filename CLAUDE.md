# Contributor rules — ai-pipeline plugin

This file applies to anyone (human or AI agent) editing this **plugin repo**. It is NOT the per-project CLAUDE.md that ships to users — that one lives at `assets/templates/CLAUDE.md`.

## Before any change

1. Understand the layered structure:
   - `commands/` — slash commands, auto-loaded (the command inventory lives in `assets/templates/PIPELINE.md` — do not restate counts here)
   - `agents/` — `senior-critic` subagent, auto-loaded
   - `assets/templates/` — files `/init` writes into user projects (do not auto-load)
   - `.claude-plugin/` — plugin manifest + marketplace entry
   - `hooks/` + `scripts/hooks/` — harness enforcement hooks, auto-loaded with the plugin (no-op outside active runs)
   - `scripts/pipeline/` — the gate bash the commands call (tested by scripts/check.sh)
   - `tests/promptfoo/` — behavioral suite (manual, pre-publish)
2. Templates in `assets/templates/` are user-facing. Changes to them ship to every new project after the next plugin update.

## Hard rules for plugin changes

1. **Templates and the per-project CLAUDE.md must stay consistent.** If you change `assets/templates/CLAUDE.md`'s rules, also check `assets/templates/PIPELINE.md` and the command files in `commands/` for drift.
2. **Lesson schema is canonical.** `assets/templates/LESSON_FORMAT.md` defines the schema. Any reference to lesson fields elsewhere (in `commands/` or `agents/senior-critic.md`) must match. Body length is a 3-sentence hard limit.
3. **Bumping the version**: any change to command behavior or template content requires a version bump in `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json`. Use semver (MAJOR.MINOR.PATCH).
4. **Test before publishing**: every change must be smoke-tested by running `/init` in `/tmp/test-<n>/` and confirming all per-project files are written correctly.
5. **Two READMEs**: `README.md` (English) and `README_RU.md` (Russian) must be updated together.
6. **No git push from inside Claude.** User pushes manually.
7. **Serena memory is the 5th context layer.** Any change to `commands/feature.md`, `commands/improve.md`, `commands/plan-improve.md`, or `agents/senior-critic.md` must keep the memory read/write logic intact (Phase 1 ground reads memories; gates auto-write suggested memories from the critic). Do not duplicate memory writes across multiple commands.
8. **`ELICITATION.md` is the canonical interview technique (v0.4.0+).** Commands reference `docs-meta/ELICITATION.md` — they never restate its content (rounds, hygiene rules, markers, weight). The playback gate (Phase 3.5) is defined only in `commands/feature.md`; `/improve` and `/fix` inherit it. Run `bash scripts/check.sh` before any version bump — it enforces this and the other hard rules.
9. **Playwright MCP is the 6th context layer (v0.3.0+).** The visual sub-step is canonical only in `commands/feature.md` Phase 9. `/improve` and `/fix` reference it; do NOT duplicate the bash/MCP block. The settings schema (`pipeline.visual_verify` in `assets/templates/settings.json`) is the source of truth for behavior; any new field must be reflected in `assets/templates/CLAUDE.md` and `assets/templates/PIPELINE.md`.

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
> /help            # confirm every command from assets/templates/PIPELINE.md appears
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
- v0.3.0 adds Playwright-MCP visual-verify gate for frontend projects; new prereq is `npx @playwright/mcp@latest` registered as MCP server (auto-registered by `/init` if `npx` is available)
- v0.4.0 adds the elicitation layer: `docs-meta/ELICITATION.md` primitive (frontier rounds, facts-vs-decisions, question hygiene), the Phase 3.5 spec playback gate, spec provenance sections, ceremony weight, `/init` interview + line-by-line confirm, and the `/questionnaire` command. No new prereqs.
- v0.5.0 adds the requirements layer: SPEC_FORMAT (EARS grammar) + living requirement files with mid identity, TRACEABILITY, risk register (gate overrides append), analogs + glossary, ADRs ([decision]-marked critic suggestions), versioned Master Plan docs, and `/release` (CHANGELOG + mid-diff + local tag). No new prereqs.
- v0.6.0 adds the math layer: project classes, docs/model.md, NUMERICS_TESTING oracle taxonomy, Phase 9c quant-verify (canonical only in feature.md — /improve and /fix carry deltas, same pattern as 9b), numeric critic duties, verify-method enum + @relation/hash code links. No new prereqs.
- v0.7.0 adds the mechanism layer: plugin hooks (hooks/hooks.json + scripts/hooks/ — ledger, Stop gate, pre-merge blocker, PreCompact snapshot, prompt injection; every script no-op-guards on non-pipeline projects), machine gate verdicts (critic JSON block + verdict.json), run-state + /resume (10th command), gate bash decomposed into scripts/pipeline/ (fixture-tested via check.sh), tests/promptfoo/ behavioral skeleton (run `npx promptfoo eval -c tests/promptfoo/promptfooconfig.yaml` manually before publishing), Playwright MCP pinned to 0.0.79 (bump deliberately + smoke test). No new prereqs.
- v1.0.0 closes the loop: Success criteria in SPEC/REQUIREMENTS formats, /validate (outcome evidence, misses routed to /plan-improve), /deprecate (migration plans, intended-break critic protocol), /lesson distill (cursor + docs-meta/DISTILLED.md, ground reads rules first), senior-critic verification mode (fresh-context finding audit before the user sees findings), docs/analysis/out-of-scope.md refusal KB. From 1.0.0 semver is enforced: breaking changes only on major. No new prereqs.

## What this plugin does NOT do

- Cross-agent compatibility (Claude Code only)
- Auto-install of system tools (`bd`, `gh`, `node`)
- Language-specific scaffolding (no `package.json` writing)
- Auto-push to remotes
