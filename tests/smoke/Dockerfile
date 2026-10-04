ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# Only sandbox infrastructure is preinstalled.
# bootstrap.sh must install the actual workstation tools itself.
RUN if command -v apt-get >/dev/null; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl sudo python3 && \
      rm -rf /var/lib/apt/lists/*; \
    else \
      dnf install -y ca-certificates curl sudo python3 && \
      dnf clean all; \
    fi && \
    useradd --create-home --shell /bin/sh dotfiles && \
    printf 'dotfiles ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/dotfiles && \
    chmod 440 /etc/sudoers.d/dotfiles && \
    touch /etc/dotfiles-test-sandbox

ENV HOME=/home/dotfiles \
    XDG_CONFIG_HOME=/home/dotfiles/.config \
    XDG_DATA_HOME=/home/dotfiles/.local/share \
    XDG_STATE_HOME=/home/dotfiles/.local/state \
    XDG_CACHE_HOME=/home/dotfiles/.cache \
    PATH=/home/dotfiles/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /dotfiles
COPY --chown=dotfiles:dotfiles . .
USER dotfiles

RUN sh tests/smoke/run.sh
