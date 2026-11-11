setup() {
  load ../../../test/helpers/consumer
}

@test "default user is coder" {
  [ "$(image_default_user)" = "coder" ]
}

@test "uid 1000 is coder with gid 1000 and home /home/coder" {
  run_as_coder sh -c 'id; echo "$HOME"'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "uid=1000(coder) gid=1000(coder) groups=1000(coder)" ]
  [ "${lines[1]}" = "/home/coder" ]
}

@test "coder's login shell is bash" {
  run_as_coder getent passwd coder
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | cut -d: -f7)" = "/bin/bash" ]
}

@test "there is no sudo" {
  run_as_coder sh -c '! command -v sudo'
  [ "$status" -eq 0 ]
}

@test "no setuid or setgid binaries exist" {
  # Directories uid 1000 can't traverse hold nothing it could execute.
  run_as_coder sh -c 'find / -xdev -type f -perm /6000 2>/dev/null'
  [ -z "$output" ]
}

@test "works with an empty home" {
  run_as_coder bash -lc 'touch "$HOME/probe" && echo ok'
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}
