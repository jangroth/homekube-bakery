#!/usr/bin/env bash
# Usage: ./lint.sh
# Runs shellcheck over every tracked shell script, bats helper and bats test.
set -euo pipefail

cd "$(dirname "$0")"
git ls-files -z '*.sh' 'test/helpers/*.bash' ':!.claude/' | xargs -0 shellcheck
git ls-files -z '*.bats' | xargs -0 shellcheck -s bats
