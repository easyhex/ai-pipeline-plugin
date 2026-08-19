#!/usr/bin/env bash
# Fixture contract for quant-verify.sh:
#   1) required mode + zero declared checks  -> partial (vacuous-verdict guard)
#   2) a check failing on one seed of [0,1]  -> failed  (pass^k)
#   3) all checks green on all seeds         -> verified
set -eu
REPO=$(cd "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
mkdir -p .claude

echo '{"pipeline":{"quant_verify":{"mode":"required","seeds":[0,1],"mutation":"off"}}}' > .claude/settings.json
bash "$REPO/scripts/pipeline/quant-verify.sh" t1 - required >/dev/null 2>&1 || true
[ "$(jq -r .status docs/superpowers/quant-evidence/t1/verdict.json)" = "partial" ] || { echo "case1: zero checks must be partial"; exit 1; }

echo '{"pipeline":{"quant_verify":{"mode":"required","seeds":[0,1],"mutation":"off","property_test_command":"test \"$SEED\" -eq 0"}}}' > .claude/settings.json
bash "$REPO/scripts/pipeline/quant-verify.sh" t2 - required >/dev/null 2>&1 || true
[ "$(jq -r .status docs/superpowers/quant-evidence/t2/verdict.json)" = "failed" ] || { echo "case2: one failing seed must be failed"; exit 1; }

echo '{"pipeline":{"quant_verify":{"mode":"required","seeds":[0,1],"mutation":"off","property_test_command":"true"}}}' > .claude/settings.json
bash "$REPO/scripts/pipeline/quant-verify.sh" t3 - required >/dev/null 2>&1
[ "$(jq -r .status docs/superpowers/quant-evidence/t3/verdict.json)" = "verified" ] || { echo "case3: all-green must be verified"; exit 1; }

echo ok
exit 0
