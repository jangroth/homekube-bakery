#!/usr/bin/env bash
# Usage: published-tags.sh <repository>   e.g. published-tags.sh jangroth/homekube-bakery/coder-workspace
# Prints the tags already published for the repository in GHCR, one per line.
set -euo pipefail

repository="$1"
if ! [[ "$repository" =~ ^[a-z0-9._-]+(/[a-z0-9._-]+)*$ ]]; then
  echo "published-tags.sh: expected a lowercase repository path, got '$repository'" >&2
  exit 1
fi
registry="${REGISTRY_URL:-https://ghcr.io}"

token=$(curl -fsS ${GITHUB_TOKEN:+-u "token:$GITHUB_TOKEN"} "$registry/token?scope=repository:$repository:pull" | jq -er .token)
body=$(mktemp)
trap 'rm -f "$body"' EXIT
status=$(curl -sS -o "$body" -w '%{http_code}' -H "Authorization: Bearer $token" "$registry/v2/$repository/tags/list")

if [ "$status" = 404 ] && jq -e '.errors[0].code == "NAME_UNKNOWN"' "$body" >/dev/null; then
  exit 0
fi
if [ "$status" != 200 ]; then
  echo "published-tags.sh: registry answered $status for $repository: $(cat "$body")" >&2
  exit 1
fi
jq -r '.tags // [] | .[]' "$body"
