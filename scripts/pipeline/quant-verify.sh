#!/usr/bin/env bash
# usage: quant-verify.sh <SLUG> <REQUIREMENTS_FILE|-> <required|best_effort>
# Runs every declared check (NFR proving commands from the requirements file +
# global pipeline.quant_verify commands + budgets) once per seed (SEED exported;
# empty seed list = one run without SEED). pass^k: all seeds must pass.
# Verdicts (anti-overclaim): verified | partial (declared check not executed,
# incl. ZERO collected checks in required mode) | failed. Writes summary.md,
# run-manifest.md, verdict.json. Exit 0 unless required-mode non-verified.
set -u
SLUG="${1:?usage: quant-verify.sh <slug> <requirements-file|-> <mode>}"
REQ="${2:--}"
MODE="${3:-required}"
S=.claude/settings.json
E="docs/superpowers/quant-evidence/$SLUG"
mkdir -p "$E"
CHECKS="$E/.checks.tsv"
: > "$CHECKS"

# NFR proving commands from the requirements file ("Proving command: <cmd> ·" lines)
if [ "$REQ" != "-" ] && [ -f "$REQ" ]; then
  grep -o 'Proving command: [^·]*' "$REQ" 2>/dev/null | sed 's/Proving command: *//' \
    | awk 'NF' | while IFS= read -r c; do
        printf 'nfr-%d\t%s\n' "$(($(wc -l < "$CHECKS") + 1))" "$c" >> "$CHECKS"
      done
fi
# global commands
for k in property_test_command benchmark_command tolerance_report_command; do
  c=$(jq -r ".pipeline.quant_verify.$k // \"\"" "$S" 2>/dev/null || echo "")
  [ -n "$c" ] && printf '%s\t%s\n' "$k" "$c" >> "$CHECKS"
done
# budgets [{name, command, ...}]
jq -c '.pipeline.quant_verify.budgets[]?' "$S" 2>/dev/null | while IFS= read -r b; do
  n=$(printf '%s' "$b" | jq -r '.name // "budget"')
  c=$(printf '%s' "$b" | jq -r '.command // ""')
  [ -n "$c" ] && printf 'budget:%s\t%s\n' "$n" "$c" >> "$CHECKS"
done

SEEDS=$(jq -r '.pipeline.quant_verify.seeds // [0] | .[]' "$S" 2>/dev/null || echo 0)
TOTAL=$(wc -l < "$CHECKS" | tr -d ' ')
STATUS=verified
NOTES=""
RESULTS=""

if [ "${TOTAL:-0}" -eq 0 ]; then
  # vacuous-verdict guard: zero collected checks in required mode is never "verified"
  if [ "$MODE" = "required" ]; then STATUS=partial; fi
  NOTES="- no checks declared (Important finding: an empty manifest proves nothing)"
else
  : > "$E/checks.log"
  while IFS="$(printf '\t')" read -r NAME CMD; do
    [ -n "$CMD" ] || continue
    PASSED=0; RUNS=0
    if [ -z "$SEEDS" ]; then
      RUNS=1
      bash -c "$CMD" >> "$E/checks.log" 2>&1 && PASSED=1
    else
      for sd in $SEEDS; do
        RUNS=$((RUNS + 1))
        SEED="$sd" bash -c "$CMD" >> "$E/checks.log" 2>&1 && PASSED=$((PASSED + 1))
      done
    fi
    RESULTS="$RESULTS
| $NAME | $PASSED/$RUNS |"
    [ "$PASSED" -lt "$RUNS" ] && STATUS=failed
  done < "$CHECKS"
fi

# mutation sub-step
MUT=$(jq -r '.pipeline.quant_verify.mutation // "advisory"' "$S" 2>/dev/null || echo advisory)
MUTC=$(jq -r '.pipeline.quant_verify.mutation_command // ""' "$S" 2>/dev/null || echo "")
if [ "$MUT" != "off" ]; then
  if [ -n "$MUTC" ]; then
    if ! bash -c "$MUTC" > "$E/mutation.log" 2>&1; then
      if [ "$MUT" = "required" ]; then STATUS=failed; fi
      NOTES="$NOTES
- mutation survivors / run failure (see mutation.log)$( [ "$MUT" = "advisory" ] && echo ' — advisory: Important finding, not a block')"
    fi
  elif [ "$MUT" = "required" ]; then
    [ "$STATUS" = "verified" ] && STATUS=partial
    NOTES="$NOTES
- mutation: required but mutation_command is empty — a declared check that cannot execute"
  fi
fi

{
  echo "# Run manifest — $SLUG"
  echo "- commit: $(git rev-parse HEAD 2>/dev/null || echo n/a)"
  echo "- date: $(date -Iseconds 2>/dev/null || date)"
  echo "- seeds: $(echo $SEEDS | tr '\n' ' ')"
  echo "- platform: $(uname -sm 2>/dev/null || echo unknown)"
  echo "- checks collected: ${TOTAL:-0}"
} > "$E/run-manifest.md"

{
  echo "# Quant verification summary"
  echo
  echo "**Slug:** $SLUG · **Mode:** $MODE · **Verdict:** $STATUS"
  echo
  echo "| Check | pass^k |"
  echo "|---|---|"
  echo "${RESULTS:-| — | — |}"
  echo
  echo "## Notes"
  echo "${NOTES:-- none}"
} > "$E/summary.md"

BLOCK=false
[ "$MODE" = "required" ] && [ "$STATUS" != "verified" ] && BLOCK=true
jq -n --arg g quant --arg slug "$SLUG" --arg s "$STATUS" --argjson b "$BLOCK" \
  '{gate: $g, slug: $slug, status: $s, blocking: $b}' > "$E/verdict.json" 2>/dev/null \
  || printf '{"gate":"quant","slug":"%s","status":"%s","blocking":%s}\n' "$SLUG" "$STATUS" "$BLOCK" > "$E/verdict.json"
rm -f "$CHECKS"
[ "$STATUS" = "verified" ] && exit 0
[ "$MODE" = "required" ] && exit 1
exit 0
