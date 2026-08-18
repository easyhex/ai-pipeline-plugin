Fenced bash blocks in this plugin's command files may execute as SEPARATE Bash tool calls with no shared shell state. Any variable needed by a block must be resolved inside that block (e.g., Phase 9b's SPEC_FILE is derived by file existence at the point of use), or the dependent blocks must be explicitly run in one shell. Never design a cross-command-file variable handoff (e.g., /fix exporting a variable for /feature's inherited phase) — it silently degrades.

Captured by senior-critic at gate-2 of the v0.3.1 patch branch on 2026-08-18.

Why stable: this is a permanent design constraint of the markdown-command architecture; it caused the /fix visual-verify URL-extraction bug and will re-trap any future phase that shares MODE/SKIP_VISUAL-style flags across blocks.