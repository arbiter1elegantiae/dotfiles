#!/bin/sh
set -eu

REPOSITORY=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$REPOSITORY"

shellcheck bootstrap.sh tests/*.sh tests/smoke/*.sh
for config in zsh/.zshrc zsh/.zprofile zsh/.p10k.zsh tests/smoke/zsh.zsh; do
  zsh -n "$config"
done
python3 tests/check-configs.py
nvim --headless -u NONE -i NONE -c "lua dofile('tests/check-lua.lua')"
./tests/bootstrap-links.sh
