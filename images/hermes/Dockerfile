FROM debian:13-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS tools

# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.104.0
# renovate: datasource=github-releases depName=coder/coder
ARG CODER_VERSION=2.39.1

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /download
RUN base="https://github.com/cli/cli/releases/download/v${GH_VERSION}" \
 && tarball="gh_${GH_VERSION}_linux_arm64.tar.gz" \
 && curl -fsSLO "$base/$tarball" \
 && curl -fsSLO "$base/gh_${GH_VERSION}_checksums.txt" \
 && awk -v f="$tarball" '$2 == f' "gh_${GH_VERSION}_checksums.txt" | sha256sum -c - \
 && tar xzf "$tarball" --strip-components=2 "gh_${GH_VERSION}_linux_arm64/bin/gh"
RUN base="https://github.com/coder/coder/releases/download/v${CODER_VERSION}" \
 && tarball="coder_${CODER_VERSION}_linux_arm64.tar.gz" \
 && curl -fsSLO "$base/$tarball" \
 && curl -fsSLO "$base/coder_${CODER_VERSION}_checksums.txt" \
 && awk -v f="$tarball" '$2 == f' "coder_${CODER_VERSION}_checksums.txt" | sha256sum -c - \
 && tar xzf "$tarball" ./coder

FROM nousresearch/hermes-agent:v0.22.2@sha256:36099926da316742423544e055d4734777105ffe6341873af5459b957d0c2919

LABEL org.opencontainers.image.source=https://github.com/jangroth/homekube-bakery

# Upstream's uv directory is versioned, so the link target is resolved at build time.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends jq \
 && rm -rf /var/lib/apt/lists/* \
 && set -- /opt/hermes/tools/uv-*-linux-arm64 \
 && [ $# -eq 1 ] && [ -x "$1/uv" ] && [ -x "$1/uvx" ] \
 && ln -s "$1/uv" /usr/local/bin/uv \
 && ln -s "$1/uvx" /usr/local/bin/uvx

COPY --from=tools --chown=root:root --chmod=755 /download/gh /download/coder /usr/local/bin/
