# Design notes

This plugin packages a 6-command AI development pipeline. The full design rationale is captured in two specs that live in the predecessor repo (the original `project_template/` directory used to develop this plugin):

- **Pipeline design** — the 6 commands, the `senior-critic` agent, the lessons system, the Master Plan split: see the original spec at `project_template/docs/superpowers/specs/2026-04-25-ai-pipeline-design.md`
- **Plugin packaging design** — turning the per-project pipeline into an installable Claude Code plugin: see `project_template/docs/superpowers/specs/2026-04-25-ai-pipeline-plugin-design.md`
- **Serena memory integration (v0.2.0)** — see the spec at `project_template/docs/superpowers/specs/2026-04-25-serena-memory-integration.md` for the full design (5-layer context model, /remember command, critic-driven auto-capture).

## Why this design

**Why 6 commands and not more?**
Each user-facing command corresponds to one cognitive operation: bootstrap, refine plan, build new, modify existing, debug, capture lesson. Internal phases (brainstorm, plan, TDD, critic, verify, finish) are not commands because the user shouldn't have to orchestrate them — that's the pipeline's job.

**Why a critic at two gates?**
Gate-1 (post-spec) catches design holes before any code is written. Gate-2 (post-diff) catches implementation drift. The critic is a senior reviewer that produces findings, not approvals — the user decides what to address.

**Why a lessons system?**
Without a feedback loop, the pipeline learns nothing across runs. `/fix` writes a lesson at the end of every debug; `senior-critic` reads them at every gate. Over weeks, the system stops repeating mistakes.

**Why Lean `/init`?**
Scaffolding a Next.js or Python skeleton is a separate, opinionated project. Most teams already have a preferred starter. The pipeline's value is the process discipline, not the file tree.

## What's not here

- **No cross-agent support.** Claude Code only. If we ever ported, we'd build a parallel npm CLI (the AI Factory model).
- **No auto-system-install.** `bd` CLI requires brew or curl; we document, we don't run.
- **No telemetry.** Lessons stay local; nothing leaves your machine.
