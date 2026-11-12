# A TLS server whose certificate is signed by a throwaway test CA, for checking which CAs a consumer trusts.

TLS_IMAGE=alpine/openssl@sha256:6821afa2476e11be343f29275f2ca24291720ff0a7148bd131fd8e314ff26d9e
export TLS_HOST=tls-server

# Writes ca.crt, server.crt and server.key for $TLS_HOST to the given directory.
make_test_ca() {
  mkdir -p "$1"
  docker run --rm -v "$1:/pki" -w /pki --entrypoint sh "$TLS_IMAGE" -c "
    openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj '/CN=bakery test CA' -keyout ca.key -out ca.crt &&
    openssl req -newkey rsa:2048 -nodes -subj '/CN=$TLS_HOST' -addext 'subjectAltName=DNS:$TLS_HOST' -keyout server.key -out server.csr &&
    openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -days 1 -copy_extensions copy -out server.crt &&
    chmod 644 ca.crt server.crt
  " 2>/dev/null
}

# Starts the server on a fresh network; sets TLS_NETWORK.
start_tls_server() {
  export TLS_NETWORK="bakery-tls-$$"
  export TLS_CONTAINER="bakery-tls-$$"
  docker network create "$TLS_NETWORK" >/dev/null
  docker run -d --name "$TLS_CONTAINER" --network "$TLS_NETWORK" --network-alias "$TLS_HOST" \
    -v "$1:/pki:ro" "$TLS_IMAGE" \
    s_server -quiet -www -accept 443 -cert /pki/server.crt -key /pki/server.key >/dev/null
  local attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    docker run --rm --network "$TLS_NETWORK" "$TLS_IMAGE" \
      s_client -connect "$TLS_HOST:443" </dev/null >/dev/null 2>&1 && return 0
    sleep 1
  done
  return 1
}

stop_tls_server() {
  docker rm -f "$TLS_CONTAINER" >/dev/null 2>&1 || true
  docker network rm "$TLS_NETWORK" >/dev/null 2>&1 || true
}
