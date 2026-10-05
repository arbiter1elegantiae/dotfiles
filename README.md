# dotfiles

Portable workstation configurations for macOS, Ubuntu/Debian, and Fedora.

## Contributing

Start with a [feature, bug, or documentation issue](https://github.com/arbiter1elegantiae/dotfiles/issues/new/choose)
and obtain owner approval of its specification before implementation. See
[AGENTS.md](AGENTS.md) for commit conventions, agent claims, parallel worktrees,
and sandbox verification. Issues are tracked through the owner's
[`dotfiles` GitHub project board](https://github.com/users/arbiter1elegantiae/projects/3).

## Bootstrap

Run the bootstrap from this repository:

```sh
./bootstrap.sh
```

It installs the base shell packages, pinned Zsh dependencies, mise, uv, Node.js
LTS, Herdr, OpenCode, Neovim, its Lua tooling, and the Tree-sitter CLI. Linux
packages include the compiler/build tools needed for Neovim parsers; on macOS,
Apple's command-line build tools are required (Homebrew installs them if needed).
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

Neovim uses the current Omarchy LazyVim configuration, including theme
hot-reloading and remote clipboard support. Plugin revisions are tracked in
`nvim/lazy-lock.json` and are not updated by bootstrap. Ghostty loads colors
from Omarchy's current theme. `herdr/config.toml` is tracked but is not yet
linked by bootstrap.

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

GitHub Actions runs on pushes, pull requests, manual dispatch, and weekly (to
catch changes in upstream installers). It uses the same test scripts as local
development:

- **Fast checks:** ShellCheck, Zsh/Lua syntax, JSON/TOML parsing, and link/backup
  idempotency tests.
- **Linux installation:** fresh Ubuntu 24.04, Debian 13, and Fedora 44 containers,
  each with an empty home and an unprivileged user with sudo. The real bootstrap
  runs twice, without mocked installers or cached tool installations.
- **macOS installation:** a fresh GitHub-hosted macOS 15 VM with an isolated,
  empty test home. Homebrew, Python, and Apple's build tools come with the runner;
  the workstation tools are installed by bootstrap.

The installation checks exercise login-shell startup, Git aliases, Zsh plugins,
history settings, tool executables and pinned versions, OpenCode's executable
link and Herdr skill, and Herdr's native config validator. Neovim checks restore
the plugin lockfile and verify every revision, then exercise editing, completion
capabilities, file-explorer loading, Git signs, Tree-sitter parsing, StyLua
formatting, a real Lua LSP request, theme hot-reloading, and remote clipboard
provider selection. Ghostty's native config validator runs on macOS.

Run the fast checks locally (requires ShellCheck, Zsh, Neovim, and Python 3.11+):

```sh
sh tests/check.sh
```

Or run only the non-destructive link and idempotency test:

```sh
./tests/bootstrap-links.sh
```

With Docker running, smoke-test the full bootstrap on the supported Linux
distributions by building the test image with each base image:

```sh
docker build --no-cache --progress=plain --build-arg BASE_IMAGE=ubuntu:24.04 -f tests/smoke/Dockerfile .
docker build --no-cache --progress=plain --build-arg BASE_IMAGE=debian:13 -f tests/smoke/Dockerfile .
docker build --no-cache --progress=plain --build-arg BASE_IMAGE=fedora:44 -f tests/smoke/Dockerfile .
```

These builds install packages and download user tools inside disposable image
layers; they do not modify the host configuration.
The full test script refuses to run outside its container or GitHub-hosted
macOS sandbox. Do not run bootstrap on the host to test an installation.

These are headless integration tests: they validate Ghostty's configuration,
not window rendering, and clipboard provider setup, not cross-machine clipboard
delivery. Herdr's tracked config is validated explicitly because bootstrap does
not yet link it. To add coverage, extend `tests/smoke/zsh.zsh` or
`tests/smoke/nvim.lua`; CI and local containers automatically use the same checks.
