next_tag() {
  run "$BATS_TEST_DIRNAME/../next-tag.sh" "$1"
}

@test "the first tag of a line is patch 0" {
  next_tag 0.2 </dev/null
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.0" ]
}

@test "the next tag follows the highest patch" {
  next_tag 0.2 <<<$'0.2.0\n0.2.1'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.2" ]
}

@test "tags from other lines are ignored" {
  next_tag 0.2 <<<$'0.1.5\n0.2.0\n0.20.7\n1.2.4\n10.2.9'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.1" ]
}

@test "gaps are not filled: the next tag follows the highest patch" {
  next_tag 0.2 <<<$'0.2.10\n0.2.0\n0.2.9'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.11" ]
}

@test "tags that are not MAJOR.MINOR.PATCH are ignored" {
  next_tag 0.2 <<<$'0.2.0\nsha256-0a1b2c.att\nv0.2.7\n0.2.foo\n0.2.8-rc1\n0.2.9.1\nlatest'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.1" ]
}
