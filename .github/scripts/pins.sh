#!/usr/bin/env bash
# Usage: pins.sh <dockerfile>
# Prints the base image and tool pins of <dockerfile>, one `from` or `tool` manifest line each.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: pins.sh <dockerfile>" >&2
  exit 1
fi

awk '
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
' "$1"
