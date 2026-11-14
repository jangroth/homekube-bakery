setup() {
  old="$BATS_TEST_TMPDIR/old"
  new="$BATS_TEST_TMPDIR/new"
}

manifest_diff() {
  run "$BATS_TEST_DIRNAME/../manifest-diff.sh" "$@"
}

@test "a package upgrade is listed under Packages with both versions" {
  cat >"$old" <<'EOF'
from debian 13-slim@sha256:aaa
package curl 8.14.1-2
package git 1:2.47.3-0+deb13u1
EOF
  cat >"$new" <<'EOF'
from debian 13-slim@sha256:aaa
package curl 8.14.1-2+deb13u1
package git 1:2.47.3-0+deb13u1
EOF
  manifest_diff "$old" "$new"
  [ "$status" -eq 0 ]
  [ "$output" = '### Packages

- `curl` 8.14.1-2 → 8.14.1-2+deb13u1' ]
}

@test "packages only in the new manifest are added, packages only in the old one are removed" {
  cat >"$old" <<'EOF'
package curl 8.14.1-2
package tree 2.2.1-1
EOF
  cat >"$new" <<'EOF'
package curl 8.14.1-2
package jq 1.7.1-6
EOF
  manifest_diff "$old" "$new"
  [ "$status" -eq 0 ]
  [ "$output" = '### Packages

- `jq` 1.7.1-6 (added)
- `tree` 2.2.1-1 (removed)' ]
}

@test "tool and base image pin changes are listed under Tools, before Packages" {
  cat >"$old" <<'EOF'
from nousresearch/hermes-agent v0.22.2@sha256:aaa
package jq 1.7.1-6
tool cli/cli 2.104.0
tool coder/coder 2.38.7
EOF
  cat >"$new" <<'EOF'
from nousresearch/hermes-agent v0.23.0@sha256:bbb
package jq 1.7.1-7
tool cli/cli 2.105.0
tool coder/coder 2.38.7
EOF
  manifest_diff "$old" "$new"
  [ "$status" -eq 0 ]
  [ "$output" = '### Tools

- `cli/cli` 2.104.0 → 2.105.0
- `nousresearch/hermes-agent` v0.22.2@sha256:aaa → v0.23.0@sha256:bbb

### Packages

- `jq` 1.7.1-6 → 1.7.1-7' ]
}

@test "a tool change alone prints only the Tools section" {
  printf 'package curl 8.14.1-2\ntool anomalyco/opencode 2.2.7\n' >"$old"
  printf 'package curl 8.14.1-2\ntool anomalyco/opencode 2.3.0\n' >"$new"
  manifest_diff "$old" "$new"
  [ "$status" -eq 0 ]
  [ "$output" = '### Tools

- `anomalyco/opencode` 2.2.7 → 2.3.0' ]
}

@test "identical manifests print nothing, meaning unchanged" {
  printf 'from debian 13-slim@sha256:aaa\npackage curl 8.14.1-2\ntool anomalyco/opencode 2.2.7\n' >"$old"
  cp "$old" "$new"
  manifest_diff "$old" "$new"
  [ "$status" -eq 0 ]
  [ "$output" = '' ]
}

@test "a missing manifest fails rather than reporting unchanged" {
  printf 'package curl 8.14.1-2\n' >"$new"
  manifest_diff "$old" "$new"
  [ "$status" -ne 0 ]
  [[ "$output" == *"manifest-diff.sh: no manifest at $old"* ]]
}

@test "a missing argument fails with usage" {
  printf 'package curl 8.14.1-2\n' >"$new"
  manifest_diff "$new"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage: manifest-diff.sh <old-manifest> <new-manifest>"* ]]
}
