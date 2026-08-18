# Enable Powerlevel10k instant prompt. Keep this near the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# User-managed executables. The unique path array prevents duplicate entries.
typeset -U path PATH
path=("$HOME/.local/bin" $path)
export PATH

# Oh My Zsh
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode disabled

# Oh My Zsh initializes compinit before loading these plugins.
plugins=(
  git
  fzf-tab
  zsh-autosuggestions
)

# Persistent command history. Keep it outside the configuration directory.
typeset -g HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
typeset -g HISTSIZE=50000
typeset -g SAVEHIST=50000

if [[ ! -d "${HISTFILE:h}" ]]; then
  command mkdir -p -m 700 "${HISTFILE:h}" ||
    print -u2 "zsh: unable to create history directory: ${HISTFILE:h}"
fi

source "$ZSH/oh-my-zsh.sh"

# Activate project and global runtimes managed by mise.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# Share timestamped history across concurrent shells, including tmux and Herdr panes.
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_FCNTL_LOCK
setopt HIST_VERIFY
setopt HIST_IGNORE_SPACE

# Native Zsh completion behavior
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' group-name ''

# fzf-tab behavior
zstyle ':fzf-tab:*' fzf-flags \
  --layout=reverse \
  --border

# Use < and > to move between completion groups.
zstyle ':fzf-tab:*' switch-group '<' '>'

# Preview directories while completing arguments to cd.
# Plain ls keeps this portable across macOS and Linux.
zstyle ':fzf-tab:complete:cd:*' \
  fzf-preview 'ls -la "$realpath"'

# Native command-line editing and history search.
bindkey -v
typeset -g KEYTIMEOUT=20

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -M viins '^[[A' up-line-or-beginning-search
bindkey -M viins '^[[B' down-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search
bindkey -M vicmd '^[[B' down-line-or-beginning-search
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward

# Powerlevel10k configuration.
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# Must remain last so every ZLE widget is visible to the highlighter.
source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
