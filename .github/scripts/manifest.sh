#!/usr/bin/env bash
# Usage: manifest.sh <dockerfile> <image-ref>
# Prints the manifest of <image-ref>: the base image and tool pins from <dockerfile>, and the installed Debian packages.
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: manifest.sh <dockerfile> <image-ref>" >&2
  exit 1
fi
dockerfile="$1"
image_ref="$2"

pins=$("$(dirname "$0")/pins.sh" "$dockerfile")

# shellcheck disable=SC2016
packages=$(docker run --rm --platform linux/arm64 --entrypoint dpkg-query "$image_ref" -W -f '${binary:Package} ${Version}\n' \
  | sed 's/^/package /')

printf '%s\n%s\n' "$pins" "$packages" | sed '/^$/d' | LC_ALL=C sort -u
