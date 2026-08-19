#!/usr/bin/env bash
# Prints the installed plugin's versioned root (highest semver in the cache).
# Single source of the resolution snippet — commands call this instead of
# restating the sort -V logic.
set -u
PLUGIN_BASE="$HOME/.claude/plugins/cache/ai-pipeline-marketplace/ai-pipeline"
[ -d "$PLUGIN_BASE" ] || { echo "" ; exit 1; }
V=$(ls "$PLUGIN_BASE" 2>/dev/null | sort -V | tail -1)
[ -n "$V" ] || { echo ""; exit 1; }
echo "$PLUGIN_BASE/$V"
exit 0
