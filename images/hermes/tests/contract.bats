setup() {
  load ../../../test/helpers/consumer
}

# The single FROM reference in the Dockerfile; fails unless it is pinned by vX.Y.Z tag and digest.
upstream_image() {
  local ref
  ref=$(sed -nE 's/^FROM[[:space:]]+([^[:space:]]+).*/\1/p' "$BATS_TEST_DIRNAME/../Dockerfile" | tr -d '\r')
  if ! [[ "$ref" =~ ^nousresearch/hermes-agent:v[0-9]+\.[0-9]+\.[0-9]+@sha256:[0-9a-f]{64}$ ]]; then
    echo "expected one FROM pinned by vX.Y.Z tag and digest, got '$ref'" >&2
    return 1
  fi
  echo "$ref"
}

# Usage: image_config <reference>
image_config() {
  docker image inspect --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}} {{json .Config.User}} {{json .Config.Volumes}}' "$1"
}

@test "the upstream Hermes image is pinned by vX.Y.Z tag and digest" {
  upstream_image
}

@test "entrypoint, cmd, user and volumes are identical to the pinned upstream Hermes image's" {
  upstream=$(upstream_image)
  docker pull -q --platform linux/arm64 "$upstream" >/dev/null
  expected=$(image_config "$upstream")
  actual=$(image_config "$IMAGE")
  [ "$actual" = "$expected" ]
}

@test "the source label points at the bakery repo" {
  [ "$(image_label org.opencontainers.image.source)" = "https://github.com/jangroth/homekube-bakery" ]
}

@test "jq, uv and uvx print their versions as uid 1000 after the upstream user remap" {
  run_as_hermes sh -c 'id -u && jq --version && uv --version && uvx --version'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "1000" ]
  [[ "${lines[1]}" =~ ^jq-[0-9]+\.[0-9]+ ]]
  [[ "${lines[2]}" =~ ^uv\ [0-9]+\.[0-9]+\.[0-9]+ ]]
  [[ "${lines[3]}" =~ ^uvx\ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "uid 1000 cannot write to jq, uv or uvx, the files they resolve to, or their directories" {
  run_as_hermes sh -c 'for tool in jq uv uvx; do
      bin=$(command -v "$tool") || { echo "$tool is not on PATH"; continue; }
      real=$(readlink -f "$bin")
      for path in "$bin" "$(dirname "$bin")" "$real" "$(dirname "$real")"; do
        [ ! -w "$path" ] || echo "$path is writable"
      done
    done'
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}
