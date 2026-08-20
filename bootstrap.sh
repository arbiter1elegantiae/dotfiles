#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
LINKS_ONLY=false

OH_MY_ZSH_REVISION=b37dd49ca5bfe0d99b35607637152cb8cc8b29d7
POWERLEVEL10K_REVISION=36f3045d69d1ba402db09d09eb12b42eebe0fa3b
FZF_TAB_REVISION=d7e0234614dbe5369fdd760907d12c0e05a4dccc
AUTOSUGGESTIONS_REVISION=e52ee8ca55bcc56a17c828767a3f98f22a68d4eb
SYNTAX_HIGHLIGHTING_REVISION=db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e
NEOVIM_VERSION=0.12.4
LUA_LANGUAGE_SERVER_VERSION=3.17.1
STYLUA_VERSION=2.3.1

log() {
  printf '==> %s\n' "$1"
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--links-only]

Install workstation dependencies and link this repository's dotfiles.

  --links-only  Skip all downloads and package installation.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --links-only)
      LINKS_ONLY=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown argument: $1"
      ;;
  esac
  shift
done

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "sudo is required to install system packages"
  fi
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  for brew_executable in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$brew_executable" ]; then
      eval "$("$brew_executable" shellenv)"
      return
    fi
  done

  die "Homebrew installed but its executable could not be located"
}

install_system_packages() {
  case "$(uname -s)" in
    Darwin)
      install_homebrew
      log "Installing macOS packages"
      brew install git zsh fzf ripgrep
      ;;
    Linux)
      [ -r /etc/os-release ] || die "unable to identify this Linux distribution"
      # shellcheck disable=SC1091
      . /etc/os-release

      case "${ID:-}" in
        ubuntu|debian)
          log "Installing Debian/Ubuntu packages"
          run_as_root apt-get update
          run_as_root env DEBIAN_FRONTEND=noninteractive \
            apt-get install -y ca-certificates curl fzf git ripgrep tar unzip wl-clipboard xclip zsh
          ;;
        fedora)
          log "Installing Fedora packages"
          run_as_root dnf install -y ca-certificates curl fzf git ripgrep tar unzip wl-clipboard xclip zsh
          ;;
        *)
          die "unsupported Linux distribution: ${ID:-unknown}"
          ;;
      esac
      ;;
    *)
      die "unsupported operating system: $(uname -s)"
      ;;
  esac
}

install_git_checkout() {
  name=$1
  url=$2
  destination=$3
  revision=$4

  if [ -e "$destination" ] && [ ! -d "$destination/.git" ]; then
    die "$destination exists but is not a Git checkout"
  fi

  if [ ! -d "$destination/.git" ]; then
    log "Installing $name"
    mkdir -p "$(dirname -- "$destination")"
    temporary_destination="${destination}.bootstrap-$$"
    if ! git clone --filter=blob:none "$url" "$temporary_destination"; then
      rm -rf "$temporary_destination"
      die "failed to clone $name"
    fi
    mv "$temporary_destination" "$destination"
  fi

  if [ -n "$(git -C "$destination" status --porcelain)" ]; then
    die "$destination has local changes; refusing to replace its revision"
  fi

  current_revision=$(git -C "$destination" rev-parse HEAD)
  if [ "$current_revision" != "$revision" ]; then
    log "Pinning $name"
    git -C "$destination" fetch --depth=1 origin "$revision"
    git -C "$destination" checkout --detach "$revision"
  fi
}

install_zsh_dependencies() {
  zsh_root=${ZSH:-$HOME/.oh-my-zsh}
  zsh_custom=${ZSH_CUSTOM:-$zsh_root/custom}

  install_git_checkout \
    "Oh My Zsh" \
    https://github.com/ohmyzsh/ohmyzsh.git \
    "$zsh_root" \
    "$OH_MY_ZSH_REVISION"
  install_git_checkout \
    "Powerlevel10k" \
    https://github.com/romkatv/powerlevel10k.git \
    "$zsh_custom/themes/powerlevel10k" \
    "$POWERLEVEL10K_REVISION"
  install_git_checkout \
    "fzf-tab" \
    https://github.com/Aloxaf/fzf-tab.git \
    "$zsh_custom/plugins/fzf-tab" \
    "$FZF_TAB_REVISION"
  install_git_checkout \
    "zsh-autosuggestions" \
    https://github.com/zsh-users/zsh-autosuggestions.git \
    "$zsh_custom/plugins/zsh-autosuggestions" \
    "$AUTOSUGGESTIONS_REVISION"
  install_git_checkout \
    "zsh-syntax-highlighting" \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$zsh_custom/plugins/zsh-syntax-highlighting" \
    "$SYNTAX_HIGHLIGHTING_REVISION"
}

install_user_tools() {
  mkdir -p "$HOME/.local/bin"

  if [ ! -x "$HOME/.local/bin/mise" ]; then
    log "Installing mise"
    curl -fsSL https://mise.run | sh
  fi

  if [ ! -x "$HOME/.local/bin/uv" ]; then
    log "Installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | \
      env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
  fi

  mise_executable=$HOME/.local/bin/mise

  if [ -z "$("$mise_executable" ls --global --installed --no-header node)" ]; then
    log "Installing Node.js LTS with mise"
    "$mise_executable" use --global node@lts
  fi

  if [ -z "$("$mise_executable" ls --global --installed --no-header herdr)" ]; then
    log "Installing Herdr with mise"
    "$mise_executable" use --global herdr
  fi

  log "Installing pinned Neovim tools with mise"
  "$mise_executable" use --global "aqua:neovim/neovim@$NEOVIM_VERSION"
  "$mise_executable" use --global "aqua:LuaLS/lua-language-server@$LUA_LANGUAGE_SERVER_VERSION"
  "$mise_executable" use --global "aqua:JohnnyMorganz/StyLua@$STYLUA_VERSION"

  if [ ! -x "$HOME/.opencode/bin/opencode" ]; then
    log "Installing OpenCode"
    curl -fsSL https://opencode.ai/install | \
      bash -s -- --no-modify-path
  fi

  link_file "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode"

  mkdir -p "$HOME/.config/opencode"
  install_herdr_skill
  log "Installing the Herdr integration for OpenCode"
  "$mise_executable" exec -- herdr integration install opencode
}

install_herdr_skill() {
  skill_directory=$HOME/.config/opencode/skills/herdr
  temporary_skill=$(mktemp "${TMPDIR:-/tmp}/herdr-skill.XXXXXX")

  if ! "$mise_executable" exec -- herdr --skill > "$temporary_skill"; then
    rm -f "$temporary_skill"
    die "failed to export the Herdr OpenCode skill"
  fi
  if [ ! -s "$temporary_skill" ]; then
    rm -f "$temporary_skill"
    die "Herdr returned an empty OpenCode skill"
  fi

  log "Installing the Herdr skill for OpenCode"
  mkdir -p "$skill_directory"
  mv "$temporary_skill" "$skill_directory/SKILL.md"
}

link_file() {
  source_file=$1
  target_file=$2

  [ -e "$source_file" ] || die "link source does not exist: $source_file"
  mkdir -p "$(dirname -- "$target_file")"

  if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
    log "Already linked: $target_file"
    return
  fi

  if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    backup_file="${target_file}.backup-$(date +%Y%m%d%H%M%S)-$$"
    log "Backing up $target_file to $backup_file"
    mv "$target_file" "$backup_file"
  fi

  log "Linking $target_file"
  ln -s "$source_file" "$target_file"
}

link_dotfiles() {
  link_file "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$SCRIPT_DIR/zsh/.zprofile" "$HOME/.zprofile"
  link_file "$SCRIPT_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  link_file "$SCRIPT_DIR/ghostty/config" "$HOME/.config/ghostty/config"
  link_file "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
}

if [ "$LINKS_ONLY" = false ]; then
  install_system_packages
  install_zsh_dependencies
  install_user_tools
fi

link_dotfiles

log "Bootstrap complete"
if [ "$LINKS_ONLY" = false ] && [ "$(basename -- "${SHELL:-sh}")" != zsh ]; then
  printf 'Zsh is installed but is not your login shell.\n'
fi
