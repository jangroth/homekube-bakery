setup() {
  readme="$BATS_TEST_TMPDIR/README.md"
  images="$BATS_TEST_TMPDIR/images"
  mkdir -p "$images/coder-workspace" "$images/hermes"
  cat >"$images/coder-workspace/Dockerfile" <<'EOF'
FROM debian:13-slim@sha256:aaa AS tools
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.105.0
FROM debian:13-slim@sha256:aaa
COPY --from=tools /download/gh /usr/local/bin/
EOF
  cat >"$images/hermes/Dockerfile" <<'EOF'
FROM debian:13-slim@sha256:aaa AS tools
# renovate: datasource=github-releases depName=coder/coder
ARG CODER_VERSION=2.39.4
FROM nousresearch/hermes-agent:v0.22.2@sha256:bbb
COPY --from=tools /download/coder /usr/local/bin/
EOF
  cat >"$readme" <<'EOF'
# bakery

## Tracked dependencies

### Coder workspace image (`coder-workspace`)

| Dependency | Version |
|---|---|
| `debian` | `13-slim` |
| `cli/cli` | `2.105.0` |

### Hermes image (`hermes`)

| Dependency | Version |
|---|---|
| `nousresearch/hermes-agent` | `v0.22.2` |
| `debian` | `13-slim` |
| `coder/coder` | `2.39.4` |

## Where things live
EOF
}

readme_drift() {
  run "$BATS_TEST_DIRNAME/../readme-drift.sh" "$@"
}

@test "a README whose tables match every Dockerfile's tracked dependencies passes silently" {
  readme_drift "$readme" "$images"
  [ "$status" -eq 0 ]
  [ "$output" = '' ]
}

@test "a README version that differs from the Dockerfile's fails, naming the image and both versions" {
  sed -i.bak 's/| `2.39.4` |/| `2.39.3` |/' "$readme"
  readme_drift "$readme" "$images"
  [ "$status" -eq 1 ]
  [ "$output" = 'readme-drift.sh: hermes: coder/coder is 2.39.4 in the Dockerfile but 2.39.3 in the README' ]
}

@test "a tracked dependency in a Dockerfile with no row in that image's README table fails" {
  awk '/^### Hermes/ { hermes = 1 } !(hermes && /`debian`/)' "$readme" >"$readme.new"
  mv "$readme.new" "$readme"
  readme_drift "$readme" "$images"
  [ "$status" -eq 1 ]
  [ "$output" = 'readme-drift.sh: hermes: debian 13-slim is in the Dockerfile but not in the README' ]
}

@test "a README row with no matching tracked dependency in that image's Dockerfile fails" {
  sed -i.bak 's/^| `cli\/cli` | `2.105.0` |$/&\
| `anomalyco\/opencode` | `2.3.2` |/' "$readme"
  readme_drift "$readme" "$images"
  [ "$status" -eq 1 ]
  [ "$output" = 'readme-drift.sh: coder-workspace: anomalyco/opencode 2.3.2 is in the README but not in the Dockerfile' ]
}

@test "CRLF line endings and trailing whitespace in the README or a Dockerfile are not drift" {
  awk '{ printf "%s  \r\n", $0 }' "$readme" >"$readme.new"
  mv "$readme.new" "$readme"
  awk '{ printf "%s\r\n", $0 }' "$images/hermes/Dockerfile" >"$images/hermes/Dockerfile.new"
  mv "$images/hermes/Dockerfile.new" "$images/hermes/Dockerfile"
  readme_drift "$readme" "$images"
  [ "$status" -eq 0 ]
  [ "$output" = '' ]
}

@test "a missing argument fails with usage" {
  readme_drift "$readme"
  [ "$status" -eq 1 ]
  [ "$output" = 'Usage: readme-drift.sh <readme> <images-dir>' ]
}

@test "a dependency listed twice under one image's heading fails, even when the last row matches" {
  sed -i.bak 's/^| `cli\/cli` | `2.105.0` |$/| `cli\/cli` | `2.104.0` |\
&/' "$readme"
  readme_drift "$readme" "$images"
  [ "$status" -eq 1 ]
  [ "$output" = 'readme-drift.sh: coder-workspace: cli/cli is listed twice in the README' ]
}

@test "a missing README fails rather than reporting every dependency as drift" {
  readme_drift "$BATS_TEST_TMPDIR/nope.md" "$images"
  [ "$status" -eq 1 ]
  [ "$output" = "readme-drift.sh: no README at $BATS_TEST_TMPDIR/nope.md" ]
}

@test "an images directory with no image Dockerfiles fails rather than reporting every row as drift" {
  readme_drift "$readme" "$BATS_TEST_TMPDIR/nope"
  [ "$status" -eq 1 ]
  [ "$output" = "readme-drift.sh: no image Dockerfiles in $BATS_TEST_TMPDIR/nope" ]
}
