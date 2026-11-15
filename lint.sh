#!/usr/bin/env bash
# Usage: ./lint.sh
# Runs shellcheck over every tracked shell script, bats helper and bats test, and checks that relative Markdown links resolve.
set -euo pipefail

cd "$(dirname "$0")"
git ls-files -z '*.sh' 'test/helpers/*.bash' ':!.claude/' | xargs -0 shellcheck
git ls-files -z '*.bats' | xargs -0 shellcheck -s bats

broken=0
while IFS= read -r doc; do
  while IFS= read -r target; do
    path="${target%%#*}"
    if [ -n "$path" ] && ! [ -e "$(dirname "$doc")/$path" ]; then
      echo "lint.sh: $doc links to missing $target" >&2
      broken=1
    fi
  done < <(grep -oE '\]\([^)[:space:]]+\)' "$doc" | sed -E 's/^\]\((.*)\)$/\1/' | grep -vE '^[a-z]+:' || true)
done < <(git ls-files '*.md' ':!.claude/')
exit "$broken"
