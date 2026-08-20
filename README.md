# dotfiles

Portable workstation configurations for macOS, Ubuntu/Debian, and Fedora.

## Bootstrap

Run the bootstrap from this repository:

```sh
./bootstrap.sh
```

It installs the base shell packages, pinned Zsh dependencies, mise, uv, Node.js
LTS, Herdr, OpenCode, Neovim, and its Lua tooling.
It also installs Herdr's bundled OpenCode skill at
`~/.config/opencode/skills/herdr/SKILL.md`. It then creates these links:

```text
zsh/.zshrc     -> ~/.zshrc
zsh/.zprofile  -> ~/.zprofile
zsh/.p10k.zsh  -> ~/.p10k.zsh
ghostty/config -> ~/.config/ghostty/config
nvim           -> ~/.config/nvim
```

Existing target files are moved to timestamped backup files before linking.
Installers are configured not to edit shell configuration files.
Ghostty itself is not installed; the bootstrap only links its configuration.

Neovim is a small, pinned configuration derived from
[Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). Plugin revisions
are tracked in `nvim/lazy-lock.json` and are not updated by bootstrap.

OpenCode remains updater-owned at `~/.opencode/bin/opencode`. The bootstrap
links that executable to `~/.local/bin/opencode`, backing up an existing target
at that path when necessary.

To link only the dotfiles without installing software:

```sh
./bootstrap.sh --links-only
```

The bootstrap does not change the login shell or remove existing NVM and Conda
installations.

## Test

Run the local, non-destructive link and idempotency test:

```sh
./tests/bootstrap-links.sh
```

With Docker running, smoke-test the full bootstrap on the supported Linux
distributions by building the test image with each base image:

```sh
docker build --build-arg BASE_IMAGE=ubuntu:24.04 -f tests/smoke/Dockerfile .
docker build --build-arg BASE_IMAGE=fedora:44 -f tests/smoke/Dockerfile .
```

These builds install packages and download user tools inside disposable image
layers; they do not modify the host configuration.
