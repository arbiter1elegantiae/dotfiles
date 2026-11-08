# Verify the real installed Zsh experience in a disposable interactive login shell.
# The Linux smoke test sources this after installation to check plugins and behavior.
setopt ERR_EXIT NO_UNSET PIPE_FAIL

fail() { print -u2 -- "$*"; exit 1; }

[[ -o interactive && -o login ]] || fail 'Expected an interactive login shell'
(( ${path[(Ie)$HOME/.local/bin]} )) || fail 'User executables are missing from PATH'
[[ -o sharehistory && -o hist_ignore_space ]] || fail 'History options are not loaded'
[[ -d ${HISTFILE:h} ]] || fail 'History directory was not created'
(( $+functions[compdef] && $+functions[_zsh_autosuggest_start] )) || fail 'Completion/autosuggestions are not loaded'
(( $+functions[_zsh_highlight] && $+functions[_p9k_precmd] )) || fail 'Highlighting/theme are not loaded'
(( $+functions[fzf-tab-complete] )) || fail 'fzf-tab is not loaded'

for tool in git fzf zsh; do
  command -v "$tool" >/dev/null || fail "Missing tool in login shell: $tool"
done
for tool in git fzf zsh; do
  "$tool" --version >/dev/null
done
[[ $ZSH_VERSION == 5.* && ${${ZSH_VERSION#5.}%%.*} -ge 8 ]] || fail 'Unsupported Zsh version'
[[ $KEYTIMEOUT == 20 ]] || fail 'Vi-mode timeout override not loaded'
[[ $(bindkey -M viins '^R') == *history-incremental-search-backward* ]] || fail 'History search binding missing'
[[ $POWERLEVEL9K_TRANSIENT_PROMPT == always ]] || fail 'Transient prompt not configured'
[[ $POWERLEVEL9K_LEFT_PROMPT_ELEMENTS == *vcs* ]] || fail 'Git prompt not configured'
[[ $(printf 'directory\nrepository\n' | fzf --filter repo) == repository ]] || fail 'fzf cannot filter completion candidates'

# Exercise the aliases rather than only asserting that they exist.
cd "$HOME"
g init --quiet alias-project
cd alias-project
[[ $(gst --porcelain) == '' ]] || fail 'Git status alias failed'

print 'Shell smoke tests passed'
