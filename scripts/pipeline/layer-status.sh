#!/usr/bin/env bash
# Prints the six-layer health banner. Degradation stays allowed — but visible.
set -u
P=""
if [ -f docs/architecture.md ] && ! grep -q UNFILLED docs/architecture.md 2>/dev/null; then
  P="master-plan ✓"
else
  P="master-plan ✗"
fi
N=$(ls .claude/lessons/*.md 2>/dev/null | wc -l | tr -d ' ')
CUR=$(cat docs-meta/.lesson-cursor 2>/dev/null || true)
if [ -n "$CUR" ]; then
  UND=$(ls .claude/lessons/ 2>/dev/null | awk -v c="$CUR" '$0 > c' | wc -l | tr -d ' ')
else
  UND=$N
fi
P="$P | lessons ${N:-0} (${UND:-0} undistilled)"
command -v bd >/dev/null 2>&1 && P="$P | beads ✓" || P="$P | beads ✗"
MCPL=$(claude mcp list 2>/dev/null || true)
printf '%s' "$MCPL" | grep -q '^serena:' && P="$P | serena ✓" || P="$P | serena ✗"
printf '%s' "$MCPL" | grep -q '^playwright:' && P="$P | playwright ✓" || P="$P | playwright ✗"
printf '%s' "$MCPL" | grep -qi 'context7' && P="$P | context7 ✓" || P="$P | context7 ~"
echo "Layers: $P"
exit 0
