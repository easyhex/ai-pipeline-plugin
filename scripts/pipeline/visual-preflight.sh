#!/usr/bin/env bash
# usage: visual-preflight.sh <SPEC_FILE>
# Reads settings, verifies Playwright MCP, probes/starts the dev server, extracts
# URLs from the spec. Prints KEY=VALUE lines (MODE, BASE_URL, SKIP_VISUAL, DEV_PID)
# and a URLS<<EOF block. SKIP_VISUAL=fail + exit 1 means required-mode failure.
set -u
SPEC_FILE="${1:?usage: visual-preflight.sh <spec-file>}"
S=.claude/settings.json
MODE=$(jq -r '.pipeline.visual_verify.mode // "required"' "$S" 2>/dev/null || echo required)
BASE_URL=$(jq -r '.pipeline.visual_verify.base_url // "http://localhost:3000"' "$S" 2>/dev/null || echo http://localhost:3000)
DEV_CMD=$(jq -r '.pipeline.visual_verify.dev_command // "auto"' "$S" 2>/dev/null || echo auto)
TIMEOUT=$(jq -r '.pipeline.visual_verify.dev_port_timeout_sec // 60' "$S" 2>/dev/null || echo 60)
echo "MODE=$MODE"
echo "BASE_URL=$BASE_URL"
if [ "$MODE" = "skip" ]; then echo "SKIP_VISUAL=yes"; exit 0; fi

if ! claude mcp list 2>/dev/null | grep -q "^playwright:"; then
  echo "WARN: Playwright MCP not registered. Re-enable: claude mcp add --scope user playwright -- npx '@playwright/mcp@0.0.79'" >&2
  if [ "$MODE" = "required" ]; then echo "SKIP_VISUAL=fail"; exit 1; fi
  echo "SKIP_VISUAL=yes"; exit 0
fi

DEV_PID=""
if ! curl -sf -o /dev/null -m 2 "$BASE_URL"; then
  if [ "$DEV_CMD" = "auto" ]; then
    if jq -e '.scripts.dev' package.json >/dev/null 2>&1; then DEV_CMD="npm run dev"
    elif jq -e '.scripts.start' package.json >/dev/null 2>&1; then DEV_CMD="npm run start"
    else
      echo "WARN: no scripts.dev / scripts.start in package.json. Set pipeline.visual_verify.dev_command." >&2
      if [ "$MODE" = "required" ]; then echo "SKIP_VISUAL=fail"; exit 1; fi
      echo "SKIP_VISUAL=yes"; exit 0
    fi
  fi
  bash -c "$DEV_CMD" >/tmp/ai-pipeline-dev.log 2>&1 &
  DEV_PID=$!
  UP=no
  i=0
  while [ "$i" -lt "$TIMEOUT" ]; do
    curl -sf -o /dev/null -m 2 "$BASE_URL" && { UP=yes; break; }
    sleep 1; i=$((i+1))
  done
  if [ "$UP" = "no" ]; then
    kill "$DEV_PID" 2>/dev/null
    echo "WARN: dev server did not answer in ${TIMEOUT}s. Log: /tmp/ai-pipeline-dev.log" >&2
    if [ "$MODE" = "required" ]; then echo "SKIP_VISUAL=fail"; exit 1; fi
    echo "SKIP_VISUAL=yes"; exit 0
  fi
  mkdir -p docs/superpowers/runs
  echo "$DEV_PID" > docs/superpowers/runs/dev-server.pid
  echo "DEV_PID=$DEV_PID"
fi

URLS=$(awk '/^## URLs to verify/{flag=1; next} /^## /{flag=0} flag && /^- /' "$SPEC_FILE" 2>/dev/null \
  | sed -E 's/^- //; s|^https?://[^/]+||' | grep -E '^/' || true)
[ -z "$URLS" ] && URLS="/"
echo "URLS<<EOF"
echo "$URLS"
echo "EOF"
exit 0
