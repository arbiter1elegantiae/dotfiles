#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
SHELLS_FILE=/etc/shells
OS_RELEASE_FILE=/etc/os-release
SYSTEM_ZSH_PATHS='/bin/zsh /usr/bin/zsh /usr/local/bin/zsh /opt/homebrew/bin/zsh /opt/local/bin/zsh'

# Shell packages follow their stable repository within Zsh 5.x, minimum 5.8.
# Git dependencies retain the tested revisions from the former bootstrap.
OH_MY_ZSH_REVISION=b37dd49ca5bfe0d99b35607637152cb8cc8b29d7
POWERLEVEL10K_REVISION=36f3045d69d1ba402db09d09eb12b42eebe0fa3b
FZF_TAB_REVISION=d7e0234614dbe5369fdd760907d12c0e05a4dccc
AUTOSUGGESTIONS_REVISION=e52ee8ca55bcc56a17c828767a3f98f22a68d4eb
SYNTAX_HIGHLIGHTING_REVISION=db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e

die() {
  printf 'error: %s\nSee %s/README.md#existing-installations for integration recommendations.\n' "$1" "$SCRIPT_DIR" >&2
  exit 1
}

case "${1:-}" in
  -h|--help)
    printf 'Usage: ./zsh/install.sh\nInstall only when Zsh is absent from the documented discovery locations.\n'
    printf 'Existing Zsh: skip without changes; integrate configs using zsh/README.md.\n'
    exit 0
    ;;
esac
[ "$#" -eq 0 ] || die 'unsupported arguments'
[ -n "${HOME:-}" ] || die 'HOME is required'

inspect_zsh() {
  candidate=$1
  parent=${candidate%/*}
  if [ -d "$parent" ] && [ ! -x "$parent" ]; then
    die "cannot search Zsh candidate directory: $parent"
  fi
  if [ ! -e "$candidate" ] && [ ! -L "$candidate" ]; then
    return # Missing paths and stale /etc/shells entries are not installations.
  fi
  if [ ! -f "$candidate" ] || [ ! -x "$candidate" ]; then
    die "cannot execute Zsh candidate: $candidate"
  fi
  version=$("$candidate" --version 2>&1) || die "Zsh candidate failed: $candidate ($version)"
  case "$version" in
    zsh\ [0-9]*) ;;
    *) die "unexpected version output from $candidate: $version" ;;
  esac
  printf 'SKIPPED: existing %s at %s; no changes made.\n' "$version" "$candidate"
  printf 'Integrate the configs yourself: %s/README.md#existing-installations\n' "$SCRIPT_DIR"
  exit 0
}

# PATH first, but also notice non-executable files which command -v can miss.
remaining_path=${PATH:-}
while :; do
  directory=${remaining_path%%:*}
  directory=${directory:-.}
  if [ -d "$directory" ] && [ ! -x "$directory" ]; then
    die "cannot search PATH directory: $directory"
  fi
  inspect_zsh "$directory/zsh"
  case "$remaining_path" in
    *:*) remaining_path=${remaining_path#*:} ;;
    *) break ;;
  esac
done
case "${SHELL:-}" in
  /*/zsh) inspect_zsh "$SHELL" ;;
esac
if [ -e "$SHELLS_FILE" ] || [ -L "$SHELLS_FILE" ]; then
  if [ ! -f "$SHELLS_FILE" ] || [ ! -r "$SHELLS_FILE" ]; then
    die "cannot read $SHELLS_FILE"
  fi
  while IFS= read -r registered_shell || [ -n "$registered_shell" ]; do
    case "$registered_shell" in
      /*/zsh) inspect_zsh "$registered_shell" ;;
    esac
  done < "$SHELLS_FILE"
fi
for candidate in $SYSTEM_ZSH_PATHS; do
  inspect_zsh "$candidate"
done
inspect_zsh "$HOME/.local/bin/zsh"

# Fresh means no discovered Zsh, not permission to overwrite old configuration.
case "$HOME" in /*) ;; *) die 'HOME must be an absolute path' ;; esac
if [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; then
  die 'HOME must be an existing writable directory'
fi
[ "${ZDOTDIR:-$HOME}" = "$HOME" ] || die 'custom ZDOTDIR requires manual integration'
[ "${ZSH:-$HOME/.oh-my-zsh}" = "$HOME/.oh-my-zsh" ] || die 'custom ZSH requires manual integration'
[ "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" = "$HOME/.oh-my-zsh/custom" ] || die 'custom ZSH_CUSTOM requires manual integration'

check_destinations() {
  for name in .zshrc .zprofile .p10k.zsh .oh-my-zsh .zshenv .zlogin .zlogout; do
    target=$HOME/$name
    if [ -e "$target" ] || [ -L "$target" ]; then
      die "existing destination/startup file: $target"
    fi
  done
}
check_destinations
for name in .zshrc .zprofile .p10k.zsh; do
  [ -r "$SCRIPT_DIR/$name" ] || die "missing configuration: $name"
done

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

platform=$(uname -s) || die 'cannot identify operating system'
case "$platform" in
  Darwin) manager=brew ;;
  Linux)
    [ -r "$OS_RELEASE_FILE" ] || die 'cannot identify Linux distribution'
    # This is the operating system's trusted distribution metadata.
    # shellcheck disable=SC1090
    . "$OS_RELEASE_FILE"
    manager=
    for family in "${ID:-}" ${ID_LIKE:-}; do
      case "$family" in
        ubuntu) manager=apt-get; break ;;
        fedora) manager=dnf; break ;;
        arch) manager=pacman; break ;;
      esac
    done
    [ -n "$manager" ] || die "unsupported Linux family: ${ID:-unknown}"
    [ ! -e /run/ostree-booted ] || die 'immutable/OSTree systems require manual integration'
    ;;
  *) die "unsupported operating system: $platform" ;;
esac
command -v "$manager" >/dev/null 2>&1 || die "$manager must already be installed and on PATH"
if [ "$manager" != brew ] && [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || die 'sudo is required for system packages'
fi

export LC_ALL=C
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1

supported_version() {
  # Strip a distribution epoch; accept package release suffixes, not prereleases.
  raw_version=${1##*:}
  case "$raw_version" in
    *[!0-9a-zA-Z.+~_-]*) return 1 ;;
    5.*) ;;
    *) return 1 ;;
  esac
  case "$raw_version" in *alpha*|*beta*|*rc*|*dev*) return 1 ;; esac
  major=${raw_version%%.*}
  minor=${raw_version#*.}
  minor=${minor%%[!0-9]*}
  case "$minor" in ''|*[!0-9]*) return 1 ;; esac
  [ "$major" = 5 ] && [ "$minor" -ge 8 ]
}

# Only request missing command dependencies; do not explicitly upgrade others.
packages=
for dependency in git fzf; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    packages="$packages $dependency"
  fi
done

case "$manager" in
  apt-get)
    command -v apt-cache >/dev/null 2>&1 || die 'apt-cache is required'
    run_as_root apt-get update
    metadata=$(apt-cache policy zsh) || die 'cannot query the Zsh package candidate'
    offered=$(printf '%s\n' "$metadata" | awk '$1 == "Candidate:" { print $2 }')
    ;;
  dnf)
    offered=$(dnf -q --refresh repoquery --available --latest-limit=1 --qf '%{evr}' zsh) || die 'dnf repoquery is required and must succeed'
    offered=$(printf '%s\n' "$offered" | sort -u)
    ;;
  pacman)
    # Arch does not support partial upgrades. The consumer updates the system
    # beforehand; never run -Sy or a whole-system upgrade inside this installer.
    metadata=$(pacman -Si zsh) || die 'pacman databases must be current and contain Zsh'
    offered=$(printf '%s\n' "$metadata" | awk '$1 == "Version" && $2 == ":" { print $3 }')
    ;;
  brew)
    metadata=$(brew info --formula zsh) || die 'cannot query the Zsh formula'
    offered=$(printf '%s\n' "$metadata" | awk '$1 == "==>" && $2 == "zsh:" && $3 == "stable" { sub(/,$/, "", $4); print $4 }')
    ;;
esac
supported_version "$offered" || die "package source offers unsupported Zsh: ${offered:-unknown}; require stable 5.x >= 5.8"
printf '==> Installing Zsh %s and missing shell prerequisites using %s\n' "$offered" "$manager"

stage=
cleanup() {
  result=$?
  if [ -n "$stage" ]; then
    rm -rf -- "$stage"
  fi
  if [ "$result" -ne 0 ]; then
    printf 'Installation incomplete; packages are not rolled back. See %s/README.md#verification-and-partial-failures\n' "$SCRIPT_DIR" >&2
  fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

# packages contains only the literal names git/fzf, intentionally word-split.
# shellcheck disable=SC2086
case "$manager" in
  apt-get) run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-upgrade "zsh=$offered" $packages ;;
  dnf) run_as_root dnf install -y "zsh-$offered" $packages ;;
  pacman) run_as_root pacman -S --needed --noconfirm "zsh=$offered" $packages ;;
  brew) brew install zsh $packages ;;
esac

if [ "$manager" = brew ]; then
  prefix=$(brew --prefix zsh) || die 'cannot locate installed Zsh'
  installed_zsh=$prefix/bin/zsh
else
  installed_zsh=/usr/bin/zsh
fi
installed_version=$("$installed_zsh" --version) || die 'installed Zsh cannot execute'
case "$installed_version" in zsh\ *) ;; *) die 'installed executable is not Zsh' ;; esac
installed_version=${installed_version#zsh }
installed_version=${installed_version%% *}
supported_version "$installed_version" || die "installed Zsh is unsupported: $installed_version"
for dependency in git fzf; do
  command -v "$dependency" >/dev/null 2>&1 || die "installed $dependency is not on PATH"
done

stage=$(mktemp -d "$HOME/.dotfiles-zsh.XXXXXX")

checkout() {
  repository=$1
  destination=$2
  revision=$3
  git init -q "$destination"
  git -C "$destination" remote add origin "https://github.com/$repository.git"
  git -C "$destination" fetch -q --depth=1 origin "$revision"
  git -C "$destination" checkout -q --detach "$revision"
}

printf '==> Preparing pinned shell plugins\n'
root=$stage/oh-my-zsh
checkout ohmyzsh/ohmyzsh "$root" "$OH_MY_ZSH_REVISION"
checkout romkatv/powerlevel10k "$root/custom/themes/powerlevel10k" "$POWERLEVEL10K_REVISION"
checkout Aloxaf/fzf-tab "$root/custom/plugins/fzf-tab" "$FZF_TAB_REVISION"
checkout zsh-users/zsh-autosuggestions "$root/custom/plugins/zsh-autosuggestions" "$AUTOSUGGESTIONS_REVISION"
checkout zsh-users/zsh-syntax-highlighting "$root/custom/plugins/zsh-syntax-highlighting" "$SYNTAX_HIGHLIGHTING_REVISION"
for name in .zshrc .zprofile .p10k.zsh; do
  "$installed_zsh" -n "$SCRIPT_DIR/$name"
done

check_destinations
mv "$root" "$HOME/.oh-my-zsh"
for name in .zshrc .zprofile .p10k.zsh; do
  ln -s "$SCRIPT_DIR/$name" "$HOME/$name"
done
printf 'INSTALLED: Zsh %s and its configuration. Login shell unchanged.\n' "$installed_version"
printf 'Use a Nerd Font v3 terminal font, then start %s. See zsh/README.md for verification.\n' "$installed_zsh"
