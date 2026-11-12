setup_file() {
  load ../../../test/helpers/tls
  export PKI="$BATS_FILE_TMPDIR/pki"
  make_test_ca "$PKI"
  start_tls_server "$PKI"
}

teardown_file() {
  load ../../../test/helpers/tls
  stop_tls_server
}

setup() {
  load ../../../test/helpers/consumer
  OUT_VOLUME="bakery-ca-out-$$"
}

teardown() {
  docker volume rm -f "$OUT_VOLUME" >/dev/null
}

@test "curl trusts a CA bundle passed through CURL_CA_BUNDLE" {
  run_as_coder_with --network "$TLS_NETWORK" -- \
    curl -fsS -o /dev/null "https://$TLS_HOST/"
  [ "$status" -eq 60 ]

  run_as_coder_with --network "$TLS_NETWORK" -v "$PKI/ca.crt:/ca.crt:ro" -e CURL_CA_BUNDLE=/ca.crt -- \
    curl -fsS -o /dev/null "https://$TLS_HOST/"
  [ "$status" -eq 0 ]
}

@test "the CA-bundle init step runs restricted and keeps the system CAs alongside the extra CA" {
  make_empty_dir "$OUT_VOLUME"
  run_ca_bundle_init "$PKI/ca.crt" "$OUT_VOLUME"
  [ "$status" -eq 0 ]

  run_as_coder_with -v "$OUT_VOLUME:/out:ro" -- \
    sh -c 'head -c "$(wc -c < /etc/ssl/certs/ca-certificates.crt)" /out/ca-certificates.crt | cmp - /etc/ssl/certs/ca-certificates.crt'
  [ "$status" -eq 0 ]

  run_as_coder_with --network "$TLS_NETWORK" -v "$OUT_VOLUME:/out:ro" -e CURL_CA_BUNDLE=/out/ca-certificates.crt -- \
    curl -fsS -o /dev/null "https://$TLS_HOST/"
  [ "$status" -eq 0 ]
}
