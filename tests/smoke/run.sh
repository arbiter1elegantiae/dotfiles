#!/bin/sh
set -eu

# Real package installation is restricted to disposable environments.
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
      *) printf 'Expected a disposable home under RUNNER_TEMP.\n' >&2; exit 1 ;;
    esac
    ;;
  *) exit 1 ;;
esac

REPOSITORY=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd -P)
export DOTFILES_TEST_REPOSITORY="$REPOSITORY"
export TERM=xterm-256color
unset ZSH ZSH_CUSTOM ZDOTDIR TMUX SSH_TTY SSH_CONNECTION HERDR_PANE_ID
unset MISE_CONFIG_FILE MISE_DATA_DIR

if [ "$(uname -s)" = Darwin ]; then
  # macOS supplies Zsh: this must skip, even with a completely empty test home.
  output=$(sh "$REPOSITORY/bootstrap.sh")
  printf '%s\n' "$output"
  printf '%s\n' "$output" | grep -q 'SKIPPED: existing zsh'
  [ -z "$(ls -A "$HOME")" ] || { printf 'Skip modified HOME\n' >&2; exit 1; }
  for name in .zshrc .zprofile .p10k.zsh; do
    /bin/zsh -n "$REPOSITORY/zsh/$name"
  done
  python3 "$REPOSITORY/tests/zsh-install.py"
  exit 0
fi

[ -z "$(ls -A "$HOME")" ] || { printf 'Expected an empty test home\n' >&2; exit 1; }
if command -v zsh >/dev/null 2>&1; then
  printf 'The installation sandbox must not supply Zsh.\n' >&2
  exit 1
fi
printf '==> Tool-absent Zsh installation\n'
sh "$REPOSITORY/bootstrap.sh"
for name in .zshrc .zprofile .p10k.zsh; do
  [ "$(readlink "$HOME/$name")" = "$REPOSITORY/zsh/$name" ]
done

printf '==> Login shell, prompt, plugins, completion, history, and aliases\n'
python3 "$REPOSITORY/tests/smoke/shell.py"

printf '==> Verify the five dependency revisions\n'
python3 - <<'PY'
import os
from pathlib import Path
import re
import subprocess

script = (Path(os.environ['DOTFILES_TEST_REPOSITORY']) / 'zsh/install.sh').read_text()
pins = dict(re.findall(r'^([A-Z0-9_]+_REVISION)=([0-9a-f]{40})$', script, re.M))
root = Path.home() / '.oh-my-zsh'
paths = {
    'OH_MY_ZSH_REVISION': root,
    'POWERLEVEL10K_REVISION': root / 'custom/themes/powerlevel10k',
    'FZF_TAB_REVISION': root / 'custom/plugins/fzf-tab',
    'AUTOSUGGESTIONS_REVISION': root / 'custom/plugins/zsh-autosuggestions',
    'SYNTAX_HIGHLIGHTING_REVISION': root / 'custom/plugins/zsh-syntax-highlighting',
}
assert len(pins) == len(paths) == 5
for name, path in paths.items():
    actual = subprocess.check_output(['git', '-C', str(path), 'rev-parse', 'HEAD'], text=True).strip()
    assert actual == pins[name], f'Wrong revision: {name}'
PY

printf '==> Repeat installation skips without touching HOME\n'
python3 - <<'PY'
import os
from pathlib import Path
import subprocess

home = Path.home()
def snapshot():
    return {str(p.relative_to(home)): (p.lstat().st_mtime_ns, p.lstat().st_size,
            os.readlink(p) if p.is_symlink() else None) for p in home.rglob('*')}
before = snapshot()
result = subprocess.run(['sh', os.environ['DOTFILES_TEST_REPOSITORY'] + '/bootstrap.sh'],
                        capture_output=True, text=True, check=True)
print(result.stdout)
assert 'SKIPPED: existing zsh' in result.stdout
assert snapshot() == before, 'Repeat installer changed HOME'
assert not list(home.glob('.dotfiles-zsh.*')), 'Staging directory leaked'
PY
printf 'Zsh installation smoke tests passed.\n'
