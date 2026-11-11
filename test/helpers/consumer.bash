# Requires IMAGE to name the image under test.

# Runs the Coder workspace image the way the Coder template's pod does.
run_as_coder() {
  run docker run --rm \
    --user 1000:1000 \
    --security-opt no-new-privileges \
    --cap-drop ALL \
    --tmpfs /home/coder:uid=1000,gid=1000 \
    "$IMAGE" "$@"
}

image_default_user() {
  docker image inspect --format '{{.Config.User}}' "$IMAGE"
}
