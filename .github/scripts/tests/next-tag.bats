next_tag() {
  run "$BATS_TEST_DIRNAME/../next-tag.sh" "$1"
}

@test "the first tag of a MAJOR.MINOR is patch 0" {
  next_tag 0.2 </dev/null
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.0" ]
}

@test "the next tag follows the highest patch" {
  next_tag 0.2 <<<$'0.2.0\n0.2.1'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.2" ]
}

@test "tags from other MAJOR.MINOR versions are ignored" {
  next_tag 0.2 <<<$'0.1.5\n0.2.0\n0.20.7\n1.2.4\n10.2.9'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.1" ]
}

@test "gaps below the highest patch are not filled" {
  next_tag 0.2 <<<$'0.2.10\n0.2.0\n0.2.9'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.11" ]
}

@test "an argument that is not MAJOR.MINOR is rejected" {
  local bad
  for bad in foo 0.2.1 $'0.2\r' 0. ''; do
    next_tag "$bad" </dev/null
    [ "$status" -ne 0 ]
  done
}

@test "trailing whitespace and carriage returns on tags are tolerated" {
  next_tag 0.2 <<<$'0.2.0\r\n0.2.1 \n0.2.2\t'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.3" ]
}

@test "tags that are not MAJOR.MINOR.PATCH are ignored" {
  next_tag 0.2 <<<$'0.2.0\nsha256-0a1b2c.att\nv0.2.7\n0.2.foo\n0.2.8-rc1\n0.2.9.1\nlatest'
  [ "$status" -eq 0 ]
  [ "$output" = "0.2.1" ]
}
