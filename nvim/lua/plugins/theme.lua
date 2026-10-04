-- Omarchy generates the current Neovim theme in the user's state directory.
-- Load it by path so this config still works when the dotfiles directory is symlinked.
local state_home = vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state")
local theme_file = state_home .. "/omarchy/current/theme/neovim.lua"
if vim.fn.filereadable(theme_file) == 1 then
	return dofile(theme_file)
end

return {
	{ "folke/tokyonight.nvim", priority = 1000 },
	{ "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}
