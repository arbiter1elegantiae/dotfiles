#!/bin/sh

set -eu

REPOSITORY=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT HUP INT TERM

export HOME=$TEST_ROOT/home
mkdir -p "$HOME"
printf 'existing zsh configuration\n' > "$HOME/.zshrc"
mkdir -p "$HOME/.config/nvim"
printf 'existing neovim configuration\n' > "$HOME/.config/nvim/marker"

assert_link() {
  target=$1
  expected_source=$2

  [ -L "$target" ] || {
    printf 'expected a symbolic link: %s\n' "$target" >&2
    exit 1
  }

  [ "$(readlink "$target")" = "$expected_source" ] || {
    printf 'unexpected link target for %s\n' "$target" >&2
    exit 1
  }
}

HOME=$HOME "$REPOSITORY/bootstrap.sh" --links-only

assert_link "$HOME/.zshrc" "$REPOSITORY/zsh/.zshrc"
assert_link "$HOME/.zprofile" "$REPOSITORY/zsh/.zprofile"
assert_link "$HOME/.p10k.zsh" "$REPOSITORY/zsh/.p10k.zsh"
assert_link "$HOME/.config/ghostty/config" "$REPOSITORY/ghostty/config"
assert_link "$HOME/.config/nvim" "$REPOSITORY/nvim"

set -- "$HOME"/.zshrc.backup-*
[ "$#" -eq 1 ] || {
  printf 'expected one .zshrc backup, found %s\n' "$#" >&2
  exit 1
}
backup_file=$1
[ "$(sed -n '1p' "$backup_file")" = "existing zsh configuration" ] || {
  printf 'the original .zshrc was not preserved\n' >&2
  exit 1
}

set -- "$HOME"/.config/nvim.backup-*
[ "$#" -eq 1 ] || {
  printf 'expected one Neovim backup, found %s\n' "$#" >&2
  exit 1
}
nvim_backup=$1
[ "$(sed -n '1p' "$nvim_backup/marker")" = "existing neovim configuration" ] || {
  printf 'the original Neovim configuration was not preserved\n' >&2
  exit 1
}

HOME=$HOME "$REPOSITORY/bootstrap.sh" --links-only

set -- "$HOME"/.zshrc.backup-*
[ "$#" -eq 1 ] || {
  printf 'the second run created an unexpected backup\n' >&2
  exit 1
}
[ "$1" = "$backup_file" ] || {
  printf 'the original backup changed after the second run\n' >&2
  exit 1
}

set -- "$HOME"/.config/nvim.backup-*
[ "$#" -eq 1 ] || {
  printf 'the second run created an unexpected Neovim backup\n' >&2
  exit 1
}
[ "$1" = "$nvim_backup" ] || {
  printf 'the original Neovim backup changed after the second run\n' >&2
  exit 1
}

printf 'bootstrap link tests passed\n'
