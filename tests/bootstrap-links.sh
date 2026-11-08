#!/bin/sh
set -eu
REPOSITORY=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
# Retain this familiar entry point, replacing the retired overwrite/link tests.
exec python3 "$REPOSITORY/tests/zsh-install.py"
