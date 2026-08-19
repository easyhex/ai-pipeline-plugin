#!/usr/bin/env bash
# Prints HAS_FRONTEND=yes|no and the rule that fired. A bare index.html without
# package.json never counts (compute repos with demo pages are not frontends).
set -u
HAS=no; RULE=""
if [ -f package.json ] && command -v jq >/dev/null 2>&1; then
  jq -e '.dependencies + .devDependencies | keys[] |
    test("^(react|vue|svelte|next|nuxt|@angular/core|solid-js|preact|@builder.io/qwik|astro)$")' \
    package.json >/dev/null 2>&1 && { HAS=yes; RULE="framework dependency in package.json"; }
fi
if [ "$HAS" = "no" ] && [ -f index.html ] && [ -f package.json ]; then
  HAS=yes; RULE="index.html alongside package.json"
fi
echo "HAS_FRONTEND=$HAS"
[ -n "$RULE" ] && echo "RULE=$RULE"
exit 0
