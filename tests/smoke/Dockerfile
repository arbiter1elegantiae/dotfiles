ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# Sandbox infrastructure only: the installer must supply Zsh, Git, and fzf.
# Arch images are rolling snapshots; update them coherently before installation.
RUN if command -v apt-get >/dev/null; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates sudo python3; \
    elif command -v dnf >/dev/null; then \
      dnf install -y ca-certificates sudo python3 dnf-plugins-core; \
    else \
      pacman -Syu --noconfirm && \
      pacman -S --needed --noconfirm ca-certificates sudo python; \
    fi && \
    mkdir -p /etc/dotfiles-empty-skel && \
    useradd --create-home --skel /etc/dotfiles-empty-skel --shell /bin/sh dotfiles && \
    printf 'dotfiles ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/dotfiles && \
    chmod 440 /etc/sudoers.d/dotfiles && \
    touch /etc/dotfiles-test-sandbox

ENV HOME=/home/dotfiles \
    XDG_CONFIG_HOME=/home/dotfiles/.config \
    XDG_DATA_HOME=/home/dotfiles/.local/share \
    XDG_STATE_HOME=/home/dotfiles/.local/state \
    XDG_CACHE_HOME=/home/dotfiles/.cache \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /dotfiles
COPY --chown=dotfiles:dotfiles . .
USER dotfiles
RUN sh tests/smoke/run.sh
