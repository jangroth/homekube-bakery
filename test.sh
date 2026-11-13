#!/usr/bin/env bash
# Usage: ./test.sh <image> [<reference>]   e.g. ./test.sh coder-workspace
# Runs the image's contract tests against a fresh local build, or against <reference> when given.
set -euo pipefail

image="${1:?usage: $0 <image> [<reference>]}"
dir="$(cd "$(dirname "$0")" && pwd)/images/$image"

if [ $# -ge 2 ]; then
  export IMAGE="$2"
  docker pull --platform linux/arm64 "$IMAGE"
else
  export IMAGE="homekube-bakery/$image:test"
  docker buildx build --platform linux/arm64 --load -t "$IMAGE" "$dir"
fi
bats "$dir/tests"
