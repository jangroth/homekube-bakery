setup() {
  git init -q -b main "$BATS_TEST_TMPDIR/repo"
  cd "$BATS_TEST_TMPDIR/repo"
  git config user.email bakery@example.com
  git config user.name bakery
  git config commit.gpgsign false
  mkdir -p images/coder-workspace images/hermes .github/scripts test/helpers
  touch images/coder-workspace/Dockerfile images/hermes/Dockerfile .github/scripts/next-tag.sh test/helpers/consumer.bash test.sh
  git add -A
  git commit -qm base
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

@test "a manual run affects every image" {
  changed_images workflow_dispatch "$before" refs/heads/main
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

@test "a ref that is not a git ref is rejected" {
  local bad
  for bad in '' main $'refs/heads/main\r'; do
    changed_images push "$before" "$bad"
    [ "$status" -ne 0 ]
    [ "$output" = "changed-images.sh: expected a git ref, got '$bad'" ]
  done
}
