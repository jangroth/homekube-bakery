FROM debian:13-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

RUN groupadd -g 1000 coder \
 && useradd -u 1000 -g 1000 -d /home/coder -s /bin/bash coder \
 && find / -xdev -type f -perm /6000 -exec chmod a-s {} +

USER coder
