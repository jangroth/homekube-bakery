FROM nousresearch/hermes-agent:v0.22.2@sha256:36099926da316742423544e055d4734777105ffe6341873af5459b957d0c2919

LABEL org.opencontainers.image.source=https://github.com/jangroth/homekube-bakery

# Upstream's uv directory is versioned, so the link target is resolved at build time.
RUN apt-get update \
 && apt-get install -y --no-install-recommends jq \
 && rm -rf /var/lib/apt/lists/* \
 && set -- /opt/hermes/tools/uv-*-linux-arm64 \
 && [ $# -eq 1 ] && [ -x "$1/uv" ] && [ -x "$1/uvx" ] \
 && ln -s "$1/uv" /usr/local/bin/uv \
 && ln -s "$1/uvx" /usr/local/bin/uvx
