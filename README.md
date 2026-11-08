# dotfiles

Workstation configurations for macOS, Fedora-based, Ubuntu-based, and Arch-based
distributions. Configuration files are the primary deliverable; optional
installers live beside each tool's configuration.

## Installation or integration?

**Use an installer only when its tool is not already installed.** If you already
have the tool, integrate the supplied configuration yourself using the tool's
recommendations, optionally assisted by an AI agent. Installers do not migrate,
merge, reconfigure, or upgrade existing tool installations.

Each installer makes robust but bounded discovery checks. A tool not found by
those checks is considered fresh for that tool, not proof of an empty system.
Unusual installation locations require manual integration. A found tool is skipped
without changes, with an integration-guide pointer; detection errors are not
treated as absence. Existing configuration conflicts are errors, not permission
to overwrite files. Read the tool README before installation.

| Tool | Configuration | Installation status |
| --- | --- | --- |
| Zsh | [`zsh/`](zsh/README.md) | Optional installer; existing-system recommendations and agent-ready prompt. |
| Ghostty | [`ghostty/config`](ghostty/README.md) | Configuration-only; install Ghostty separately and integrate manually. |
| Neovim | `nvim/` | Manual integration; installer/review pending. |
| Herdr | `herdr/config.toml` | Manual integration; installer/review pending. |

The broader refactor is tracked in [Epic #7](https://github.com/arbiter1elegantiae/dotfiles/issues/7).
Neovim and Herdr files are retained unchanged during this transition, including
their current Omarchy integrations; those will be reviewed separately.

## Optional bootstrap

```sh
sh bootstrap.sh
# Or just the relevant tool:
sh zsh/install.sh
```

The bootstrap is a thin sequential launcher, currently for **Zsh only**. It
continues after existing-tool skips and stops on actual errors. Tool-specific
logic belongs in each tool directory. Additional installers require individual
review; Ghostty is intentionally configuration-only and is not part of bootstrap.

This deliberately replaces the old monolithic bootstrap: no `--links-only`,
unconditional configuration replacement, or automatic installation of mise, uv,
Node, OpenCode, Herdr, Neovim, or their integrations. Those tools remain under your
existing installation ownership. The Zsh installer never changes the login shell.

## Verification

```sh
sh tests/check.sh
```

The fast suite requires ShellCheck, Zsh, Neovim, and Python 3.11+. It checks shell
and Lua syntax, JSON/TOML parsing, and isolated installer/launcher fixtures. To run
just the non-destructive installer contract tests (Python 3.11+):

```sh
./tests/bootstrap-links.sh
```

That script now tests discovery, refusal, conflict preservation, staged deployment,
and launcher delegation—not the retired backup-and-replace behavior.

For real installation checks, use disposable containers, never the host bootstrap:

```sh
docker build --no-cache --progress=plain --build-arg BASE_IMAGE=ubuntu:24.04 -f tests/smoke/Dockerfile .
docker build --no-cache --progress=plain --build-arg BASE_IMAGE=fedora:44 -f tests/smoke/Dockerfile .
docker build --no-cache --progress=plain --build-arg BASE_IMAGE=archlinux:base -f tests/smoke/Dockerfile .
```

Linux checks install Zsh into an unprivileged empty test home, exercise plugins,
prompt, history, completion, and aliases, then verify a repeat-run skip. macOS CI
checks the normal existing-Zsh skip with a disposable home. Fast fixtures simulate
the absent-Zsh Homebrew branch; they do not establish real absent-Zsh installation
on macOS. CI also runs weekly to catch package-source drift. Neovim and Herdr
retain independent syntax/parsing checks; their full installation tests remain
deferred. For Ghostty's native configuration validation and manual appearance
checks, see [its guide](ghostty/README.md#verification-and-recovery).

## Contributing

Start with a [feature, bug, or documentation issue](https://github.com/arbiter1elegantiae/dotfiles/issues/new/choose)
and obtain owner approval of its specification before implementation. See
[AGENTS.md](AGENTS.md) for commit conventions, agent claims, parallel worktrees,
and sandbox verification. Issues are tracked on the
[`dotfiles` project board](https://github.com/users/arbiter1elegantiae/projects/3).
