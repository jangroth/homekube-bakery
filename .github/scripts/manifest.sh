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

pins=$(awk '
  { sub(/\r$/, "") }
  toupper($1) == "FROM" {
    ref = ""
    for (i = 2; i <= NF; i++) if ($i !~ /^--/) { ref = $i; break }
    if (toupper($(i + 1)) == "AS") stage[tolower($(i + 2))] = 1
    if (!(tolower(ref) in stage)) {
      name = ref
      sub(/[:@].*/, "", name)
      print "from", name, substr(ref, length(name) + 2)
    }
  }
  match($0, /^# renovate: .*depName=[^ ]+/) {
    dep = substr($0, RSTART, RLENGTH)
    sub(/.*depName=/, "", dep)
    next
  }
  dep != "" && toupper($1) == "ARG" {
    value = $2
    sub(/^[^=]*=/, "", value)
    print "tool", dep, value
  }
  { dep = "" }
' "$dockerfile")

# shellcheck disable=SC2016
packages=$(docker run --rm --platform linux/arm64 --entrypoint dpkg-query "$image_ref" -W -f '${binary:Package} ${Version}\n' \
  | sed 's/^/package /')

printf '%s\n%s\n' "$pins" "$packages" | sed '/^$/d' | LC_ALL=C sort -u
