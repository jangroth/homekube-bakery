load ../../../test/helpers/consumer
load ../../../test/helpers/tls

# Creates a volume shaped like a pod emptyDir: empty and mode 0777.
make_emptydir_volume() {
  docker volume create "$1" >/dev/null
  docker run --rm --user 0 -v "$1:/d" "$IMAGE" chmod 777 /d
}

# Runs the CA-bundle init container: the system bundle plus <extra-ca>, written to <out-volume>/ca-certificates.crt.
run_ca_bundle_init() {
  run_as_coder_with -v "$1:/extra/ca.crt:ro" -v "$2:/out" -- \
    sh -c 'cat /etc/ssl/certs/ca-certificates.crt /extra/ca.crt > /out/ca-certificates.crt'
}

setup_file() {
  export PKI="$BATS_FILE_TMPDIR/pki"
  make_test_ca "$PKI"
  start_tls_server "$PKI"
}

teardown_file() {
  stop_tls_server
}

setup() {
  OUT_VOLUME="bakery-ca-out-$$"
}

teardown() {
  docker volume rm -f "$OUT_VOLUME" >/dev/null
}

@test "curl trusts a CA bundle passed through CURL_CA_BUNDLE" {
  curl_tls_server
  [ "$status" -eq 60 ] # peer certificate not trusted

  curl_tls_server -v "$PKI/ca.crt:/ca.crt:ro" -e CURL_CA_BUNDLE=/ca.crt
  [ "$status" -eq 0 ]
}

@test "the CA-bundle init step runs restricted and keeps the system CAs alongside the extra CA" {
  make_emptydir_volume "$OUT_VOLUME"
  run_ca_bundle_init "$PKI/ca.crt" "$OUT_VOLUME"
  [ "$status" -eq 0 ]

  run_as_coder_with -v "$OUT_VOLUME:/out:ro" -- \
    sh -c 'head -c "$(wc -c < /etc/ssl/certs/ca-certificates.crt)" /out/ca-certificates.crt | cmp - /etc/ssl/certs/ca-certificates.crt'
  [ "$status" -eq 0 ]

  curl_tls_server -v "$OUT_VOLUME:/out:ro" -e CURL_CA_BUNDLE=/out/ca-certificates.crt
  [ "$status" -eq 0 ]
}
