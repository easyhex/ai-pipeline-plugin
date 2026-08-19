#!/usr/bin/env bash
# usage: visual-verdict.sh <SLUG> <MODE>
# Analyzes docs/superpowers/visual-evidence/<SLUG>/ (screenshots/, snapshots/,
# console.txt, urls.txt written by the MCP steps) → summary.md + verdict.json.
# Exit 0 = PASS, exit 1 = FAIL.
set -u
SLUG="${1:?usage: visual-verdict.sh <slug> <mode>}"
MODE="${2:?usage: visual-verdict.sh <slug> <mode>}"
FC=$(jq -r 'if .pipeline.visual_verify.fail_on_console_error == false then "false" else "true" end' .claude/settings.json 2>/dev/null || echo true)
E="docs/superpowers/visual-evidence/$SLUG"
mkdir -p "$E"
URLS=$( [ -f "$E/urls.txt" ] && cat "$E/urls.txt" || echo "/" )
VERDICT=PASS
REASONS=""
slugify() {
  case "$1" in
    /) echo _root ;;
    *) echo "$1" | sed -E 's|\?.*||; s|^/||; s|/|_|g; s|[^a-zA-Z0-9_]|_|g; s|__+|_|g; s|^_||; s|_$||' | tr A-Z a-z ;;
  esac
}
for path in $URLS; do
  s=$(slugify "$path")
  png="$E/screenshots/${s}.png"
  snap="$E/snapshots/${s}.md"
  if [ ! -s "$png" ]; then
    VERDICT=FAIL; REASONS="$REASONS
- $path: screenshot missing"
  else
    sz=$(stat -f%z "$png" 2>/dev/null || stat -c%s "$png" 2>/dev/null || echo 0)
    if [ "${sz:-0}" -lt 1024 ]; then
      VERDICT=FAIL; REASONS="$REASONS
- $path: screenshot < 1KB (likely blank)"
    fi
  fi
  if [ ! -s "$snap" ]; then
    VERDICT=FAIL; REASONS="$REASONS
- $path: accessibility snapshot empty"
  fi
done
if [ "$FC" = "true" ] && grep -qiE '\[error\]|console\.error|TypeError|ReferenceError' "$E/console.txt" 2>/dev/null; then
  VERDICT=FAIL; REASONS="$REASONS
- console error(s) detected — see console.txt"
fi
cat > "$E/summary.md" <<EOF2
# Visual verification summary

**Slug:** $SLUG
**Date:** $(date -Iseconds 2>/dev/null || date)
**Mode:** $MODE
**URLs visited:** $(echo $URLS | tr '\n' ' ')
**Verdict:** $VERDICT

## Reasons (if FAIL)
$REASONS
EOF2
BLOCK=false
[ "$VERDICT" = "FAIL" ] && [ "$MODE" = "required" ] && BLOCK=true
STATUS=pass; [ "$VERDICT" = "FAIL" ] && STATUS=fail
jq -n --arg g visual --arg slug "$SLUG" --arg s "$STATUS" --argjson b "$BLOCK" \
  '{gate: $g, slug: $slug, status: $s, blocking: $b}' > "$E/verdict.json" 2>/dev/null \
  || printf '{"gate":"visual","slug":"%s","status":"%s","blocking":%s}\n' "$SLUG" "$STATUS" "$BLOCK" > "$E/verdict.json"
[ "$VERDICT" = "PASS" ] && exit 0 || exit 1
