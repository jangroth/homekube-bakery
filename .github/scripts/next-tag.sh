#!/usr/bin/env bash
# Usage: next-tag.sh <MAJOR.MINOR> < tags
# Reads the tags already published, one per line, and prints the tag to publish next.
set -euo pipefail

major_minor="$1"
if ! [[ "$major_minor" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "next-tag.sh: expected MAJOR.MINOR, got '$major_minor'" >&2
  exit 1
fi

awk -F. -v major_minor="$major_minor" '
  { sub(/[[:space:]]+$/, "") }
  NF == 3 && $1 "." $2 == major_minor && $3 ~ /^[0-9]+$/ && $3 >= next_patch { next_patch = $3 + 1 }
  END { print major_minor "." next_patch + 0 }
'
