# Zsh

These files define the shell experience; they are useful independently of the
installer. **Run `install.sh` only when Zsh is not installed. If you already have
Zsh, integrate the configurations yourself using the recommendations below,
optionally with an agent.** Installation is not migration or an upgrade command.

## Configuration

| File | Purpose |
| --- | --- |
| `.zprofile` | Homebrew environment in macOS login shells. |
| `.zshrc` | Oh My Zsh/Git aliases, fzf-tab completion with directory previews, autosuggestions, syntax highlighting, vi-mode, shared history, `~/.local/bin` on PATH, and optional mise activation. |
| `.p10k.zsh` | Powerlevel10k prompt: directory/Git state, failures, durations, jobs, project/cloud contexts, remote identity, clock, instant and transient prompts. |

Up/down navigate lines or search history; Ctrl-R uses **native Zsh** incremental
history search, not an fzf history picker. History holds 50,000 entries in
`${XDG_STATE_HOME:-~/.local/state}/zsh/history`; leading-space commands are omitted.
Use a Nerd Font v3 terminal font, such as JetBrainsMono Nerd Font. Fonts and mise
are not installed by this script; mise is activated only if already available.
There is no Omarchy dependency in these shell files.

## Optional installation

From the repository, as the intended user (not `sudo ./zsh/install.sh`):

```sh
sh zsh/install.sh
```

Supported platform families are macOS (Homebrew), Fedora-based (dnf), Ubuntu-based
(apt), and Arch-based (pacman). The native package manager must already be available
on PATH, with working stable repositories and network access. Linux uses root or
sudo for package installation. Derivatives are identified using `ID`/`ID_LIKE` in
`/etc/os-release`; immutable/OSTree or other variants without the required mutable
package-management capabilities need manual integration. Fedora's `dnf repoquery`
must be available. macOS normally includes Zsh, so the script skips before needing
Homebrew. On Arch, **bring the system and repository databases up to date yourself
first**; the script never runs `pacman -Sy` or a whole-system upgrade.

The script checks, in order:

1. `zsh` files in PATH directories, including non-executable/broken candidates.
2. An absolute `$SHELL` path ending in `/zsh`.
3. Absolute Zsh paths in `/etc/shells`, when present.
4. `/bin/zsh`, `/usr/bin/zsh`, `/usr/local/bin/zsh`,
   `/opt/homebrew/bin/zsh`, `/opt/local/bin/zsh`.
5. `~/.local/bin/zsh`.

An executable must identify itself with `--version`; no startup files are sourced
for discovery. Missing paths/stale registrations are ignored, but broken candidates
or failed checks are errors. A found Zsh is **SKIPPED** without changes and returns
success, allowing the root launcher to continue. This includes OS-bundled shells
and a previous successful installation from this script.

Not found by these bounded checks means **fresh for Zsh**, not an empty workstation
or proof that Zsh is absent everywhere. If you have an unusual installation outside
these locations, use integration recommendations rather than the installer.

Before installation, destination conflicts and redirected startup/plugin layouts
are refused. Existing `.zshrc`, `.zprofile`, `.p10k.zsh`, `.oh-my-zsh`, `.zshenv`,
`.zlogin`, or `.zlogout` (including broken symlinks) are never replaced. There is
no force/merge/backup-and-replace mode. Do not run installers concurrently.

### Versions and owned locations

- Zsh: latest stable package offered by the selected source **within major 5,
  minimum 5.8**. The offered version is checked first and installed Zsh is checked
  again before configuration activation. No source-build fallback or automatic
  major migration. This is not a promise of the newest upstream release.
- Git and fzf: request them only if their commands are missing. Package managers
  can install required dependencies; this is not a zero-system-change operation.
  Repositories must provide working Git HTTPS access and a usable fzf.
- Oh My Zsh, Powerlevel10k, fzf-tab, zsh-autosuggestions, and
  zsh-syntax-highlighting: retain the tested commit pins recorded in `install.sh`.
  Updating these revisions is a separate compatibility change.

The package manager owns the Zsh executable. The script prepares the pinned Git
checkouts in a temporary directory under HOME, then installs them at
`~/.oh-my-zsh`, with the theme/plugins under `custom/`. It syntax-checks the three
files and links them into HOME only after dependencies are prepared. The links
point into this checkout: keep the repository in place. No runtime/application
installation, existing-shell upgrades, or login-shell changes are performed.

### Verification and partial failures

Start a new interactive login shell (`zsh -l`) and check:

- Prompt, Git state, command failure/duration, and remote/project context.
- Tab completion with fuzzy selection, directory previews, suggestions, and
  syntax highlighting.
- Vi-mode, Ctrl-R, up/down, and shared history across two shell sessions.
- `command -v git fzf`, `~/.local/bin` on PATH, and mise if you already use it.

Inspect startup diagnostics before deciding whether to change your login shell.
Login-shell selection is a separate user decision.

Failures return nonzero. Completed package operations are **not rolled back**.
The temporary plugin directory is removed on normal exit/signals, but a crash or
SIGKILL may leave `.dotfiles-zsh.*` directories. Plugin-download failures do not
activate the dotfiles. A failure during final deployment may leave some owned
paths/links in place; inspect them before any cleanup. Never remove unrelated
files. If Zsh has already been installed, another run skips: finish configuration
using the integration recommendations. If it remains absent, resolve the reported
error/conflict before retrying. There is no automatic repair operation.

## Existing installations

Treat this setup as the desired behavior, not as files to overwrite blindly:

1. Identify your Zsh version, install owner, startup files (`ZDOTDIR` included),
   framework/plugin manager, and required environment initialization.
2. Compare your setup with the files above. Preserve necessary local settings
   such as proxy setup, credentials helpers, and runtime initialization.
3. Arrange the required framework/theme/plugins using your existing installation
   approach. Avoid loading completion, plugins, or runtime hooks twice. Respect
   the ordering in `.zshrc`: instant prompt early, highlighting last.
4. Decide which settings to adopt and where they belong. Back up your existing
   files before making the agreed changes; do not assume symlinking all three
   files preserves your existing behavior.
5. Validate syntax and the checks above in a new shell while retaining a working
   session. Restore your backups if integration fails.

Installation location/version choices belong to you. The provided files assume
Oh My Zsh's conventional layout (or your explicit `ZSH`/`ZSH_CUSTOM` overrides).
No universal merging or upgrade procedure is promised.

### Agent-ready integration prompt

```text
Integrate the Zsh configuration from <repository>/zsh into my existing shell.
Read zsh/README.md and the three dotfiles as the desired-behavior specification.
Do not run the fresh-install script or the root bootstrap to perform integration.
Inspect my Zsh version, startup locations, dependency owners, plugins, and required
local environment settings. Explain conflicts and propose minimal changes before
editing. Preserve unrelated behavior; do not upgrade/reinstall tools or change my
login shell without approval. Back up agreed edits, validate syntax and the README
behavior checks, and explain restoration. Ask about any uncertain local settings.
```
