setup() {
  load ../../../test/helpers/consumer
}

# The final stage's FROM reference in the Dockerfile; fails unless it is pinned by vX.Y.Z tag and digest.
upstream_image() {
  local ref
  ref=$(sed -nE 's/^FROM[[:space:]]+([^[:space:]]+).*/\1/p' "$BATS_TEST_DIRNAME/../Dockerfile" | tail -n 1 | tr -d '\r')
  if ! [[ "$ref" =~ ^nousresearch/hermes-agent:v[0-9]+\.[0-9]+\.[0-9]+@sha256:[0-9a-f]{64}$ ]]; then
    echo "expected the final FROM pinned by vX.Y.Z tag and digest, got '$ref'" >&2
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

@test "gh and coder print their versions as uid 1000 after the upstream user remap" {
  run_as_hermes sh -c 'id -u && gh --version | head -n 1 && coder --version | head -n 1'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "1000" ]
  [[ "${lines[1]}" =~ ^gh\ version\ [0-9]+\.[0-9]+\.[0-9]+ ]]
  [[ "${lines[2]}" =~ ^Coder\ v[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "uid 1000 cannot write to jq, uv, uvx, gh or coder, the files they resolve to, or their directories" {
  run_as_hermes sh -c 'for tool in jq uv uvx gh coder; do
      bin=$(command -v "$tool") || { echo "$tool is not on PATH"; continue; }
      real=$(readlink -f "$bin")
      for path in "$bin" "$(dirname "$bin")" "$real" "$(dirname "$real")"; do
        [ ! -w "$path" ] || echo "$path is writable"
      done
    done'
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "the uncompressed bytes added over the pinned upstream Hermes image are within the 535 MB budget" {
  upstream=$(upstream_image)
  docker pull -q --platform linux/arm64 "$upstream" >/dev/null
  added=$(( $(image_size) - $(image_size "$upstream") ))
  [ "$added" -le 535000000 ]
}
