FROM debian:13-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS opencode

# renovate: datasource=github-releases depName=anomalyco/opencode
ARG OPENCODE_VERSION=2.3.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /download
RUN base="https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}" \
 && curl -fsSLO "$base/opencode-linux-arm64.tar.gz" \
 && curl -fsSLO "$base/SHA256SUMS" \
 && grep '  opencode-linux-arm64\.tar\.gz$' SHA256SUMS | sha256sum -c - \
 && tar xzf opencode-linux-arm64.tar.gz opencode

FROM debian:13-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

LABEL org.opencontainers.image.source=https://github.com/jangroth/homekube-bakery

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends curl git openssh-client bash tree ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -g 1000 coder \
 && useradd -u 1000 -g 1000 -d /home/coder -s /bin/bash coder \
 && find / -xdev -type f -perm /6000 -exec chmod a-s {} +

COPY --from=opencode --chown=root:root --chmod=755 /download/opencode /usr/local/bin/opencode

USER coder
