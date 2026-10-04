#!/bin/sh
set -eu

# Full installation tests are deliberately restricted to disposable CI systems.
case "$(uname -s)" in
  Linux)
    if [ ! -f /etc/dotfiles-test-sandbox ] || [ "$HOME" != /home/dotfiles ] || [ "$(id -u)" -eq 0 ]; then
      printf 'Run this test with tests/smoke/Dockerfile in a fresh container.\n' >&2
      exit 1
    fi
    ;;
  Darwin)
    if [ "${GITHUB_ACTIONS:-}" != true ] || [ "${RUNNER_ENVIRONMENT:-}" != github-hosted ]; then
      printf 'Run this test on a disposable GitHub-hosted macOS runner.\n' >&2
      exit 1
    fi
    case "$HOME" in
      "$RUNNER_TEMP"/dotfiles-home.*) ;;
      *) printf 'Expected a fresh test home under RUNNER_TEMP.\n' >&2; exit 1 ;;
    esac
    ;;
  *) exit 1 ;;
esac

REPOSITORY=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd -P)
export DOTFILES_TEST_REPOSITORY="$REPOSITORY"
export PATH="$HOME/.local/bin:$PATH"
export TERM=xterm-256color
# Avoid inheriting shell or runtime configuration from the runner.
unset ZSH ZSH_CUSTOM ZDOTDIR TMUX SSH_TTY SSH_CONNECTION HERDR_PANE_ID
unset WAYLAND_DISPLAY DISPLAY MISE_CONFIG_FILE MISE_DATA_DIR

if [ -e "$HOME/.zshrc" ] || [ -e "$HOME/.local/bin/mise" ]; then
  printf 'The sandbox home must be empty before bootstrap.\n' >&2
  exit 1
fi

cp "$REPOSITORY/nvim/lazy-lock.json" "$HOME/expected-lazy-lock.json"
printf '\n==> Full bootstrap in a clean home\n'
"$REPOSITORY/bootstrap.sh"
printf '\n==> Repeat bootstrap to check idempotency\n'
"$REPOSITORY/bootstrap.sh"

for target in .zshrc .zprofile .p10k.zsh .config/ghostty/config .config/nvim .local/bin/opencode; do
  if [ ! -L "$HOME/$target" ] || [ ! -e "$HOME/$target" ]; then
    printf 'Missing or broken installed link: %s\n' "$target" >&2
    exit 1
  fi
done
python3 - <<'PY'
from pathlib import Path
home = Path.home()
backups = list(home.glob(".*.backup-*")) + list((home / ".config").glob("*.backup-*"))
backups += list((home / ".local/bin").glob("*.backup-*"))
assert not backups, f"Repeat bootstrap unexpectedly backed up installed files: {backups}"
assert (home / ".config/opencode/skills/herdr/SKILL.md").stat().st_size > 0
assert (home / ".local/bin/opencode").resolve() == home / ".opencode/bin/opencode"
assert (home / "expected-lazy-lock.json").read_bytes() == (
    home / ".config/nvim/lazy-lock.json"
).read_bytes(), "Bootstrap modified the plugin lockfile"
PY

printf '\n==> Login shell, aliases, plugins, and installed tools\n'
python3 "$REPOSITORY/tests/smoke/shell.py"

printf '\n==> Validate tracked Herdr configuration\n'
mise exec -- env HERDR_CONFIG_PATH="$REPOSITORY/herdr/config.toml" herdr config check

if [ "$(uname -s)" = Darwin ]; then
  printf '\n==> Validate Ghostty configuration\n'
  /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config \
    --config-file="$HOME/.config/ghostty/config"
fi

printf '\n==> Neovim first startup and plugin installation\n'
mise exec -- nvim --headless \
  -c 'lua dofile(vim.env.DOTFILES_TEST_REPOSITORY .. "/tests/smoke/install-nvim.lua")'
# Lazy rewrites its lockfile during incremental first-time installation. Restore
# the repository snapshot before explicitly restoring the recorded revisions.
# This copy is inside the disposable sandbox, never in the host checkout.
cp "$HOME/expected-lazy-lock.json" "$REPOSITORY/nvim/lazy-lock.json"
printf '\n==> Restore and check locked Neovim plugins\n'
mise exec -- nvim --headless '+Lazy! restore' \
  -c 'lua dofile(vim.env.DOTFILES_TEST_REPOSITORY .. "/tests/smoke/install-nvim.lua")'
printf '\n==> Neovim editing, formatting, Git, LSP, themes, and clipboard\n'
mkdir -p "$HOME/smoke-project"
git -C "$HOME/smoke-project" init
printf 'local value={1,2,3}\nreturn value\n' > "$HOME/smoke-project/example.lua"
git -C "$HOME/smoke-project" add example.lua
git -C "$HOME/smoke-project" -c user.name=Smoke -c user.email=smoke@example.invalid commit -m fixture
mise exec -- nvim --headless -c 'lua dofile(vim.env.DOTFILES_TEST_REPOSITORY .. "/tests/smoke/nvim.lua")'
python3 - <<'PY'
import json
import os
from pathlib import Path
expected = json.loads((Path.home() / "expected-lazy-lock.json").read_text())
actual = json.loads((Path(os.environ["DOTFILES_TEST_REPOSITORY"]) / "nvim/lazy-lock.json").read_text())
# Lazy may normalize upstream branch names; the committed revisions must match.
assert {name: entry["commit"] for name, entry in actual.items()} == {
    name: entry["commit"] for name, entry in expected.items()
}, "Neovim changed the recorded plugin revisions"
PY

printf '\nAll bootstrap smoke tests passed.\n'
