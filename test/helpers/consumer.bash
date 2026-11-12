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

# Creates a volume shaped like a pod emptyDir: empty and mode 0777.
make_empty_dir() {
  docker volume create "$1" >/dev/null
  docker run --rm --user 0 -v "$1:/d" "$IMAGE" chmod 777 /d
}

# Runs the CA-bundle init container: the system bundle plus <extra-ca>, written to <out-volume>/ca-certificates.crt.
run_ca_bundle_init() {
  run_as_coder_with -v "$1:/extra/ca.crt:ro" -v "$2:/out" -- \
    sh -c 'cat /etc/ssl/certs/ca-certificates.crt /extra/ca.crt > /out/ca-certificates.crt'
}

image_default_user() {
  docker image inspect --format '{{.Config.User}}' "$IMAGE"
}
