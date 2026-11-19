#!/usr/bin/env bash
# Usage: readme-drift.sh <readme> <images-dir>
# Prints each way the README's tracked dependency tables disagree with the image Dockerfiles, and fails if any do.
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: readme-drift.sh <readme> <images-dir>" >&2
  exit 1
fi
readme="$1"
images_dir="$2"
scripts="$(dirname "$0")"
if ! [ -f "$readme" ]; then
  echo "readme-drift.sh: no README at $readme" >&2
  exit 1
fi
dockerfiles=("$images_dir"/*/Dockerfile)
if ! [ -f "${dockerfiles[0]}" ]; then
  echo "readme-drift.sh: no image Dockerfiles in $images_dir" >&2
  exit 1
fi

# Prints `<image> <dependency> <version>` for each row under a "### … (`<image>`)" heading in "## Tracked dependencies".
readme_rows() {
  awk '
    { sub(/[[:space:]]+$/, "") }
    /^## / { section = ($0 == "## Tracked dependencies"); image = ""; next }
    section && /^### / { image = $0; sub(/^[^`]*`/, "", image); sub(/`.*/, "", image); next }
    section && image != "" && /^\| `[^`]+` \| `[^`]+` \|$/ {
      split($0, cell, "`")
      print image, cell[2], cell[4]
    }
  ' "$readme"
}

# Prints `<image> <dependency> <version>` for each tracked dependency, without digests.
dockerfile_dependencies() {
  for dockerfile in "${dockerfiles[@]}"; do
    image=$(basename "$(dirname "$dockerfile")")
    "$scripts/pins.sh" "$dockerfile" | awk -v image="$image" '{ version = $3; sub(/@.*/, "", version); print image, $2, version }'
  done
}

drift=$(awk '
  FILENAME == ARGV[1] {
    if (($1 " " $2) in readme) printf "readme-drift.sh: %s: %s is listed twice in the README\n", $1, $2
    readme[$1 " " $2] = $3
    next
  }
  { dockerfile[$1 " " $2] = $3 }
  END {
    for (key in dockerfile) {
      split(key, k, " ")
      if (!(key in readme))
        printf "readme-drift.sh: %s: %s %s is in the Dockerfile but not in the README\n", k[1], k[2], dockerfile[key]
      else if (readme[key] != dockerfile[key])
        printf "readme-drift.sh: %s: %s is %s in the Dockerfile but %s in the README\n", k[1], k[2], dockerfile[key], readme[key]
    }
    for (key in readme) {
      split(key, k, " ")
      if (!(key in dockerfile))
        printf "readme-drift.sh: %s: %s %s is in the README but not in the Dockerfile\n", k[1], k[2], readme[key]
    }
  }
' <(readme_rows) <(dockerfile_dependencies) | LC_ALL=C sort)

if [ -n "$drift" ]; then
  echo "$drift" >&2
  exit 1
fi
