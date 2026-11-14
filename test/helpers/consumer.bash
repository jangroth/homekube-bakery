# Requires IMAGE to name the image under test.

# Runs the Coder workspace image the way the Coder template's pod does.
run_as_coder() {
  run_as_coder_with -- "$@"
}

# Usage: run_as_coder_with <docker run options>... -- <command>...
run_as_coder_with() {
  run_as_init_step_with --tmpfs /home/coder:uid=1000,gid=1000 "$@"
}

# Runs a command as a consumer's init step does: entrypoint replaced, 1000:1000, no-new-privileges, no capabilities.
# Usage: run_as_init_step_with <docker run options>... -- <command>...
run_as_init_step_with() {
  local opts=()
  while [ "$1" != "--" ]; do opts+=("$1"); shift; done
  shift
  run docker run --rm \
    --user 1000:1000 \
    --security-opt no-new-privileges \
    --cap-drop ALL \
    "${opts[@]}" \
    --entrypoint "$1" "$IMAGE" "${@:2}"
}

# Creates a volume shaped like a pod emptyDir: empty and mode 0777.
make_emptydir_volume() {
  docker volume create "$1" >/dev/null
  docker run --rm --user 0 -v "$1:/d" --entrypoint chmod "$IMAGE" 777 /d
}

# Runs the Hermes image the way herminator's main container does: root start, entrypoint intact, user remapped to 1000:1000.
# $output and $lines hold only the command's stdout; upstream's boot log precedes the marker.
run_as_hermes() {
  local marker="bakery-command-output-$$-$RANDOM"
  bats_require_minimum_version 1.5.0
  run --separate-stderr docker run --rm -e HERMES_UID=1000 -e HERMES_GID=1000 \
    "$IMAGE" sh -c 'echo "$0" && exec "$@"' "$marker" "$@"
  output=$(awk -v marker="$marker" 'seen; $0 == marker { seen = 1 }' <<<"$output")
  lines=()
  local line
  if [ -n "$output" ]; then
    while IFS= read -r line; do lines+=("$line"); done <<<"$output"
  fi
}

image_default_user() {
  docker image inspect --format '{{.Config.User}}' "$IMAGE"
}

# Usage: image_label <key>
image_label() {
  docker image inspect --format "{{index .Config.Labels \"$1\"}}" "$IMAGE"
}

# Uncompressed bytes; `docker image inspect .Size` is compressed under the containerd image store.
image_size() {
  docker history --human=false --format '{{.Size}}' "$IMAGE" | awk '{ s += $1 } END { print s }'
}
