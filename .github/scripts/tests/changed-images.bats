setup() {
  git init -q -b main "$BATS_TEST_TMPDIR/repo"
  cd "$BATS_TEST_TMPDIR/repo" || return
  git config user.email bakery@example.com
  git config user.name bakery
  git config commit.gpgsign false
  mkdir -p images/coder-workspace images/hermes .github/scripts test/helpers
  touch images/coder-workspace/Dockerfile images/hermes/Dockerfile .github/scripts/next-tag.sh test/helpers/consumer.bash test.sh
  git add -A
  git commit -qm base
  git tag coder-workspace/0.1.0
  git tag hermes/0.1.0
  before=$(git rev-parse HEAD)
}

# Usage: commit_change <path>
commit_change() {
  echo change >>"$1"
  git add -A
  git commit -qm "change $1"
}

changed_images() {
  run "$BATS_TEST_DIRNAME/../changed-images.sh" "$@"
}

@test "a change to an image's directory affects only that image" {
  commit_change images/hermes/Dockerfile
  changed_images push "$before" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["hermes"]' ]
}

@test "on main, an image change since its last release stays affected after a CI-only push" {
  commit_change images/hermes/Dockerfile
  local unpublished
  unpublished=$(git rev-parse HEAD)
  commit_change .github/scripts/next-tag.sh
  changed_images push "$unpublished" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["hermes"]' ]
}

@test "on main, an image that was never released is affected" {
  git tag -d hermes/0.1.0 >/dev/null
  commit_change .github/scripts/next-tag.sh
  changed_images push "$before" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["hermes"]' ]
}

@test "on main, each image is compared against its own last release" {
  commit_change images/coder-workspace/Dockerfile
  commit_change images/hermes/Dockerfile
  git tag hermes/0.1.1
  commit_change .github/scripts/next-tag.sh
  changed_images push "$before" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["coder-workspace"]' ]
}

@test "on main, a tag that is not a plain version doesn't count as a release" {
  commit_change images/hermes/Dockerfile
  git tag hermes/0.2.0-rc1
  git tag hermes/latest
  changed_images push "$before" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["hermes"]' ]
}

@test "on main, a shallow clone is rejected because release tags may be missing" {
  git clone -q --depth 1 "file://$PWD" "$BATS_TEST_TMPDIR/shallow"
  cd "$BATS_TEST_TMPDIR/shallow" || return
  changed_images push "$before" refs/heads/main
  [ "$status" -ne 0 ]
  [ "$output" = "changed-images.sh: shallow clone on main, release tags may be missing" ]
}

@test "a deleted image is never affected" {
  git rm -rq images/hermes
  git commit -qm "delete hermes"
  local ref
  for ref in refs/heads/main refs/heads/renovate/debian; do
    changed_images push "$before" "$ref"
    [ "$status" -eq 0 ]
    [ "$output" = '[]' ]
  done
}

@test "a manual run affects every image" {
  changed_images workflow_dispatch "$before" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["coder-workspace","hermes"]' ]
}

@test "a scheduled run affects every image, even with nothing changed since their releases" {
  changed_images schedule "" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["coder-workspace","hermes"]' ]
}

@test "a CI change on a branch affects every image" {
  commit_change .github/scripts/next-tag.sh
  changed_images push "$before" refs/heads/renovate/debian
  [ "$status" -eq 0 ]
  [ "$output" = '["coder-workspace","hermes"]' ]
}

@test "a CI change on main affects no image, so nothing republishes" {
  commit_change .github/scripts/next-tag.sh
  changed_images push "$before" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '[]' ]
}

@test "a shared test helper change on main affects every image" {
  commit_change test/helpers/consumer.bash
  changed_images push "$before" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["coder-workspace","hermes"]' ]
}

@test "a test runner change on main affects every image" {
  commit_change test.sh
  changed_images push "$before" refs/heads/main
  [ "$status" -eq 0 ]
  [ "$output" = '["coder-workspace","hermes"]' ]
}

@test "a ref that is not a git ref is rejected" {
  local bad
  for bad in '' main $'refs/heads/main\r'; do
    changed_images push "$before" "$bad"
    [ "$status" -ne 0 ]
    [ "$output" = "changed-images.sh: expected a git ref, got '$bad'" ]
  done
}
