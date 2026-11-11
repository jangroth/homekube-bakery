#!/usr/bin/env bash
# Usage: ./test.sh <image>   e.g. ./test.sh coder-workspace
set -euo pipefail

image="${1:?usage: $0 <image>}"
dir="$(cd "$(dirname "$0")" && pwd)/images/$image"
export IMAGE="homekube-bakery/$image:test"

docker buildx build --platform linux/arm64 --load -t "$IMAGE" "$dir"
bats "$dir/tests"
