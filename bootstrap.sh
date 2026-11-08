#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)

case "${1:-}" in
  -h|--help)
    printf 'Usage: ./bootstrap.sh\nRun the available tool installers sequentially (currently Zsh).\n'
    printf 'Existing tools are skipped; integrate their configs using each tool README.\n'
    exit 0
    ;;
esac
if [ "$#" -ne 0 ]; then
  printf 'error: unsupported arguments; see ./bootstrap.sh --help\n' >&2
  exit 1
fi

# Add each tool here only when its fresh-install procedure is implemented.
# shellcheck disable=SC2043
for tool in zsh; do
  printf '==> %s\n' "$tool"
  if sh "$SCRIPT_DIR/$tool/install.sh"; then
    : # Existing tools report SKIPPED and return success.
  else
    printf 'error: %s installer failed; stopping bootstrap\n' "$tool" >&2
    exit 1
  fi
done
printf '==> Available installers finished (installed or skipped).\n'
