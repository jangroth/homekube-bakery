load ../../../test/helpers/consumer
load ../../../test/helpers/tls

# Runs herminator's CA-bundle init step: the system bundle plus <extra-ca>, written to <out-volume>/ca-certificates.crt.
run_ca_bundle_init() {
  run_as_init_step_with -v "$1:/extra/ca.crt:ro" -v "$2:/out" -- \
    sh -c 'cat /etc/ssl/certs/ca-certificates.crt /extra/ca.crt > /out/ca-certificates.crt'
}

setup_file() {
  export PKI="$BATS_FILE_TMPDIR/pki"
  make_test_ca "$PKI"
}

setup() {
  OUT_VOLUME="bakery-ca-out-$$"
}

teardown() {
  docker volume rm -f "$OUT_VOLUME" >/dev/null
}

@test "sh and cat run restricted with the entrypoint replaced" {
  run_as_init_step_with -- sh -c 'echo ok | cat'
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "the CA bundle is at /etc/ssl/certs/ca-certificates.crt" {
  run_as_init_step_with -- grep -c "BEGIN CERTIFICATE" /etc/ssl/certs/ca-certificates.crt
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "the CA-bundle init step runs restricted and writes the system CAs followed by the extra CA" {
  make_emptydir_volume "$OUT_VOLUME"
  run_ca_bundle_init "$PKI/ca.crt" "$OUT_VOLUME"
  [ "$status" -eq 0 ]

  run_as_init_step_with -v "$PKI/ca.crt:/extra/ca.crt:ro" -v "$OUT_VOLUME:/out:ro" -- sh -c '
    out=/out/ca-certificates.crt system=/etc/ssl/certs/ca-certificates.crt extra=/extra/ca.crt
    head -c "$(wc -c < "$system")" "$out" | cmp - "$system" &&
    tail -c "$(wc -c < "$extra")" "$out" | cmp - "$extra" &&
    [ "$(wc -c < "$out")" -eq $(( $(wc -c < "$system") + $(wc -c < "$extra") )) ]'
  [ "$status" -eq 0 ]
}
