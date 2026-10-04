setopt ERR_EXIT NO_UNSET PIPE_FAIL

fail() { print -u2 -- "$*"; exit 1; }
expected_version() { sed -n "s/^$1=//p" "$DOTFILES_TEST_REPOSITORY/bootstrap.sh"; }

[[ -o interactive && -o login ]] || fail 'Expected an interactive login shell'
(( ${path[(Ie)$HOME/.local/bin]} )) || fail 'User executables are missing from PATH'
[[ -o sharehistory && -o hist_ignore_space ]] || fail 'History options are not loaded'
[[ -d ${HISTFILE:h} ]] || fail 'History directory was not created'
(( $+functions[compdef] && $+functions[_zsh_autosuggest_start] )) || fail 'Completion/autosuggestions are not loaded'
(( $+functions[_zsh_highlight] && $+functions[_p9k_precmd] )) || fail 'Highlighting/theme are not loaded'
(( $+functions[fzf-tab-complete] )) || fail 'fzf-tab is not loaded'

for tool in git fzf rg mise uv node npm herdr opencode nvim lua-language-server stylua tree-sitter cc; do
  command -v "$tool" >/dev/null || fail "Missing tool in login shell: $tool"
done
for tool in git fzf rg mise uv node npm herdr opencode stylua tree-sitter; do
  "$tool" --version >/dev/null
done
nvim --version >/dev/null
lua-language-server --version >/dev/null
[[ $(node -p '6 * 7') == 42 ]] || fail 'Node cannot execute JavaScript'
[[ $(nvim --version) == *"NVIM v$(expected_version NEOVIM_VERSION)"* ]] || fail 'Wrong Neovim version'
[[ $(stylua --version) == *"$(expected_version STYLUA_VERSION)"* ]] || fail 'Wrong StyLua version'
[[ $(lua-language-server --version) == *"$(expected_version LUA_LANGUAGE_SERVER_VERSION)"* ]] || fail 'Wrong Lua language server version'
[[ $(tree-sitter --version) == *"$(expected_version TREE_SITTER_VERSION)"* ]] || fail 'Wrong Tree-sitter version'

# Exercise the aliases rather than only asserting that they exist.
cd "$HOME"
g init --quiet alias-project
cd alias-project
[[ $(gst --porcelain) == '' ]] || fail 'Git status alias failed'

print 'Shell smoke tests passed'
