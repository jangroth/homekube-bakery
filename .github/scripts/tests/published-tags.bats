setup() {
  registry_dir="$BATS_TEST_TMPDIR/registry"
  mkdir -p "$registry_dir"
  python3 "$BATS_TEST_DIRNAME/fake_registry.py" "$registry_dir" >"$BATS_TEST_TMPDIR/port" 3>&- &
  registry_pid=$!
  while [ ! -s "$BATS_TEST_TMPDIR/port" ]; do sleep 0.05; done
  REGISTRY_URL="http://127.0.0.1:$(cat "$BATS_TEST_TMPDIR/port")"
  export REGISTRY_URL
}

teardown() {
  kill "$registry_pid"
  wait "$registry_pid" 2>/dev/null || true
}

# Usage: publish <repository> <tags.json body>
publish() {
  mkdir -p "$registry_dir/$1"
  echo "$2" >"$registry_dir/$1/tags.json"
}

published_tags() {
  run "$BATS_TEST_DIRNAME/../published-tags.sh" "$1"
}

@test "a published image's tags are listed one per line" {
  publish jangroth/homekube-bakery/coder-workspace '{"name":"jangroth/homekube-bakery/coder-workspace","tags":["0.2.0","sha256-0a1b2c.att","0.2.1"]}'
  published_tags jangroth/homekube-bakery/coder-workspace
  [ "$status" -eq 0 ]
  [ "$output" = $'0.2.0\nsha256-0a1b2c.att\n0.2.1' ]
}

@test "an image that was never published has no tags" {
  published_tags jangroth/homekube-bakery/coder-workspace
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "a registry error fails rather than reading as no tags" {
  local code
  for code in 401 404 500; do
    mkdir -p "$registry_dir/jangroth/homekube-bakery/coder-workspace"
    echo "$code" >"$registry_dir/jangroth/homekube-bakery/coder-workspace/status"
    published_tags jangroth/homekube-bakery/coder-workspace
    [ "$status" -ne 0 ]
    [[ "$output" == *"registry answered $code"* ]]
  done
}

@test "an image whose tags were all deleted has no tags" {
  publish jangroth/homekube-bakery/coder-workspace '{"name":"jangroth/homekube-bakery/coder-workspace","tags":null}'
  published_tags jangroth/homekube-bakery/coder-workspace
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "a private image's tags are listed with GITHUB_TOKEN" {
  publish jangroth/homekube-bakery/coder-workspace '{"name":"jangroth/homekube-bakery/coder-workspace","tags":["0.2.0"]}'
  echo "token:s3cret" >"$registry_dir/credentials"
  GITHUB_TOKEN=s3cret published_tags jangroth/homekube-bakery/coder-workspace
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.0" ]
}

@test "an argument that is not a lowercase repository path is rejected" {
  local bad
  for bad in '' Jangroth/homekube-bakery/coder-workspace 'jangroth/coder workspace' $'jangroth/homekube-bakery/coder-workspace\r' /coder-workspace jangroth//coder-workspace; do
    published_tags "$bad"
    [ "$status" -ne 0 ]
    [[ "$output" == *"expected a lowercase repository path"* ]]
  done
}
