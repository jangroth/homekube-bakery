#!/usr/bin/env bash
# Usage: manifest-diff.sh <old-manifest> <new-manifest>
# Prints the difference between two manifests as release-note sections, or nothing if they match.
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: manifest-diff.sh <old-manifest> <new-manifest>" >&2
  exit 1
fi
old="$1"
new="$2"
for manifest in "$old" "$new"; do
  if ! [ -f "$manifest" ]; then
    echo "manifest-diff.sh: no manifest at $manifest" >&2
    exit 1
  fi
done

# Usage: changes <kind-regex>
changes() {
  awk -v kinds="^($1)\$" '
    $1 !~ kinds { next }
    FILENAME == ARGV[1] { old[$2] = $3; next }
    { new[$2] = $3 }
    END {
      for (name in new) {
        if (!(name in old)) printf "%s\t- `%s` %s (added)\n", name, name, new[name]
        else if (old[name] != new[name]) printf "%s\t- `%s` %s → %s\n", name, name, old[name], new[name]
      }
      for (name in old) if (!(name in new)) printf "%s\t- `%s` %s (removed)\n", name, name, old[name]
    }
  ' "$old" "$new" | LC_ALL=C sort -t $'\t' -k1,1 | cut -f2-
}

sections=()
tools=$(changes 'from|tool')
if [ -n "$tools" ]; then
  sections+=("$(printf '### Tools\n\n%s' "$tools")")
fi
packages=$(changes package)
if [ -n "$packages" ]; then
  sections+=("$(printf '### Packages\n\n%s' "$packages")")
fi

if [ ${#sections[@]} -gt 0 ]; then
  printf '%s\n\n' "${sections[@]}" | sed '$d'
fi
