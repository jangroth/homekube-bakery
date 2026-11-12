# Requires IMAGE to name the image under test.

# Runs the Coder workspace image the way the Coder template's pod does.
run_as_coder() {
  run_as_coder_with -- "$@"
}

# Usage: run_as_coder_with <docker run options>... -- <command>...
run_as_coder_with() {
  local opts=()
  while [ "$1" != "--" ]; do opts+=("$1"); shift; done
  shift
  run docker run --rm \
    --user 1000:1000 \
    --security-opt no-new-privileges \
    --cap-drop ALL \
    --tmpfs /home/coder:uid=1000,gid=1000 \
    "${opts[@]}" \
    "$IMAGE" "$@"
}

image_default_user() {
  docker image inspect --format '{{.Config.User}}' "$IMAGE"
}

# Uncompressed bytes; `docker image inspect .Size` is compressed under the containerd image store.
image_size() {
  docker history --human=false --format '{{.Size}}' "$IMAGE" | awk '{ s += $1 } END { print s }'
}
