#!/usr/bin/env bash
# Usage: changed-images.sh <event> <before-sha> <ref>
# Prints a JSON array of the images under images/ that need building. On main, <before-sha> is ignored.
set -euo pipefail

event="$1"
before="$2"
ref="$3"
if ! [[ "$ref" =~ ^refs/[^[:space:]]+$ ]]; then
  echo "changed-images.sh: expected a git ref, got '$ref'" >&2
  exit 1
fi

shared=(test test.sh)

all_images() { find images -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort; }

if [ "$event" = workflow_dispatch ] || [ "$event" = schedule ]; then
  images=$(all_images)
elif [ "$ref" = refs/heads/main ]; then
  if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
    echo "changed-images.sh: shallow clone on main, release tags may be missing" >&2
    exit 1
  fi
  # Main publishes, so each image is compared with its last release; CI-only changes don't count.
  images=""
  while read -r image; do
    last_release_tag=$("$(dirname "$0")/last-release-tag.sh" "$image")
    if [ -z "$last_release_tag" ] || ! git diff --quiet "$last_release_tag" HEAD -- "images/$image" "${shared[@]}"; then
      images+="$image"$'\n'
    fi
  done < <(all_images)
else
  if ! git cat-file -e "$before^{commit}" 2>/dev/null; then
    before=$(git merge-base origin/main HEAD)
  fi
  if ! git diff --quiet "$before" HEAD -- "${shared[@]}" .github; then
    images=$(all_images)
  else
    # Existing directories only: a deleted image shows up in the diff too.
    images=$(git diff --name-only "$before" HEAD -- images | sed -nE 's|^images/([^/]+)/.*|\1|p' | sort -u \
      | while read -r i; do if [ -d "images/$i" ]; then echo "$i"; fi; done)
  fi
fi

jq -Rnc '[inputs | select(length > 0)]' <<<"$images"
