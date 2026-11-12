#!/usr/bin/env bash
# Usage: next-tag.sh <MAJOR.MINOR> < tags
# Reads the tags already published, one per line, and prints the tag to publish next.
set -euo pipefail

line="$1"

awk -F. -v line="$line" '
  NF == 3 && $1 "." $2 == line && $3 ~ /^[0-9]+$/ && $3 >= next_patch { next_patch = $3 + 1 }
  END { print line "." next_patch + 0 }
'
