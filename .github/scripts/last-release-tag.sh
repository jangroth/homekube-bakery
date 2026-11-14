#!/usr/bin/env bash
# Usage: last-release-tag.sh <image>   e.g. last-release-tag.sh coder-workspace
# Prints the image's highest release git tag merged into HEAD, such as coder-workspace/0.2.0, or nothing if it has none.
set -euo pipefail

image="$1"
if ! [[ "$image" =~ ^[a-z0-9._-]+$ ]]; then
  echo "last-release-tag.sh: expected an image name, got '$image'" >&2
  exit 1
fi

git tag --list "$image/*" --merged HEAD --sort=-v:refname | grep -m1 -xE "$image/[0-9]+\.[0-9]+\.[0-9]+" || true
