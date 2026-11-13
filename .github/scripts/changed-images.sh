#!/usr/bin/env bash
# Usage: changed-images.sh <event> <before-sha> <ref>
# Prints a JSON array of the images under images/ that need building.
set -euo pipefail

event="$1"
before="$2"
ref="$3"
if ! [[ "$ref" =~ ^refs/[^[:space:]]+$ ]]; then
  echo "changed-images.sh: expected a git ref, got '$ref'" >&2
  exit 1
fi

shared='^(test/|test\.sh$|\.github/)'
# Building on main publishes, and CI changes alone don't change an image.
if [ "$ref" = refs/heads/main ]; then
  shared='^(test/|test\.sh$)'
fi

all_images() { find images -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort; }

if [ "$event" = workflow_dispatch ]; then
  images=$(all_images)
else
  if ! git cat-file -e "$before^{commit}" 2>/dev/null; then
    before=$(git merge-base origin/main HEAD)
  fi
  changed=$(git diff --name-only "$before" HEAD)
  if grep -qE "$shared" <<<"$changed"; then
    images=$(all_images)
  else
    # Existing directories only: a deleted image shows up in the diff too.
    images=$(sed -nE 's|^images/([^/]+)/.*|\1|p' <<<"$changed" | sort -u \
      | while read -r i; do if [ -d "images/$i" ]; then echo "$i"; fi; done)
  fi
fi

jq -Rnc '[inputs | select(length > 0)]' <<<"$images"
