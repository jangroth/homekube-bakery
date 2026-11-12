#!/usr/bin/env bash
# Usage: changed-images.sh <event> <before-sha>
# Prints a JSON array of the images under images/ that need building.
set -euo pipefail

event="$1"
before="$2"

all_images() { find images -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort; }

if [ "$event" = workflow_dispatch ]; then
  images=$(all_images)
else
  if ! git cat-file -e "$before^{commit}" 2>/dev/null; then
    before=$(git merge-base origin/main HEAD)
  fi
  changed=$(git diff --name-only "$before" HEAD)
  if grep -qE '^(test/|test\.sh$|\.github/)' <<<"$changed"; then
    images=$(all_images)
  else
    # Existing directories only: a deleted image shows up in the diff too.
    images=$(sed -nE 's|^images/([^/]+)/.*|\1|p' <<<"$changed" | sort -u \
      | while read -r i; do if [ -d "images/$i" ]; then echo "$i"; fi; done)
  fi
fi

jq -Rnc '[inputs | select(length > 0)]' <<<"$images"
