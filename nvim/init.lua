-- Minimal personal configuration derived from kickstart.nvim at e79572c.
-- See LICENSE.md for the upstream MIT license.

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = false

vim.o.number = true
vim.o.mouse = "a"
vim.o.showmode = false
vim.o.autoread = true
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split"
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = vim.diagnostic.severity.ERROR },
	virtual_text = true,
	virtual_lines = false,
	jump = { float = true },
})

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics quickfix list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Focus lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Focus upper window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right window" })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Check for edits made by coding agents without discarding unsaved buffers.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	group = vim.api.nvim_create_augroup("check-external-changes", { clear = true }),
	command = "checktime",
})
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	group = vim.api.nvim_create_augroup("external-change-notice", { clear = true }),
	callback = function()
		vim.notify("Reloaded file changed outside Neovim")
	end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_revision = "306a05526ada86a7b30af95c5cc81ffba93fef97"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local output = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Unable to clone lazy.nvim:\n" .. output)
	end
end
local output = vim.fn.system({ "git", "-C", lazypath, "checkout", "--detach", lazy_revision })
if vim.v.shell_error ~= 0 then
	error("Unable to pin lazy.nvim:\n" .. output)
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(buffer)
				local gitsigns = require("gitsigns")
				local function map(mode, keys, action, description)
					vim.keymap.set(mode, keys, action, { buffer = buffer, desc = description })
				end
				map("n", "]c", gitsigns.next_hunk, "Next Git hunk")
				map("n", "[c", gitsigns.prev_hunk, "Previous Git hunk")
				map("n", "<leader>hp", gitsigns.preview_hunk, "Preview Git hunk")
				map("n", "<leader>hs", gitsigns.stage_hunk, "Stage Git hunk")
				map("n", "<leader>hr", gitsigns.reset_hunk, "Reset Git hunk")
				map("v", "<leader>hs", function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Stage Git hunk")
				map("v", "<leader>hr", function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Reset Git hunk")
				map("n", "<leader>hb", gitsigns.blame_line, "Blame Git line")
				map("n", "<leader>hd", gitsigns.diffthis, "Diff against Git index")
				map("n", "<leader>hD", function()
					gitsigns.diffthis("~")
				end, "Diff against Git HEAD")
			end,
		},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
		keys = { { "\\", "<cmd>Neotree reveal<CR>", desc = "Reveal file tree" } },
		opts = {
			filesystem = {
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true,
			},
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-ui-select.nvim" },
		config = function()
			local telescope = require("telescope")
			telescope.setup({ extensions = { ["ui-select"] = require("telescope.themes").get_dropdown() } })
			telescope.load_extension("ui-select")
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Live grep" })
			vim.keymap.set({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "Grep word" })
			vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "Find buffers" })
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "Select Telescope picker" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Resume Telescope picker" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = "Find recent files" })
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "Find Neovim files" })
			vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git status" })
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp" },
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
				callback = function(event)
					local function map(keys, action, description, mode)
						vim.keymap.set(mode or "n", keys, action, { buffer = event.buf, desc = description })
					end
					map("grn", vim.lsp.buf.rename, "Rename symbol")
					map("gra", vim.lsp.buf.code_action, "Code action", { "n", "x" })
					map("grD", vim.lsp.buf.declaration, "Go to declaration")
					local telescope = require("telescope.builtin")
					map("grr", telescope.lsp_references, "Find references")
					map("gri", telescope.lsp_implementations, "Go to implementation")
					map("grd", telescope.lsp_definitions, "Go to definition")
					map("gO", telescope.lsp_document_symbols, "Document symbols")
					map("gW", telescope.lsp_dynamic_workspace_symbols, "Workspace symbols")
					map("grt", telescope.lsp_type_definitions, "Go to type definition")
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client:supports_method("textDocument/documentHighlight", event.buf) then
						local group = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd(
							{ "CursorHold", "CursorHoldI" },
							{ buffer = event.buf, group = group, callback = vim.lsp.buf.document_highlight }
						)
						vim.api.nvim_create_autocmd(
							{ "CursorMoved", "CursorMovedI" },
							{ buffer = event.buf, group = group, callback = vim.lsp.buf.clear_references }
						)
					end
					if client and client:supports_method("textDocument/inlayHint", event.buf) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "Toggle inlay hints")
					end
				end,
			})
			vim.lsp.config("lua_ls", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
				settings = {
					Lua = {
						runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
						workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
					},
				},
			})
			vim.lsp.enable("lua_ls")
		end,
	},
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				desc = "Format buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(buffer)
				if vim.bo[buffer].filetype == "c" or vim.bo[buffer].filetype == "cpp" then
					return
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
			formatters_by_ft = { lua = { "stylua" } },
		},
	},
	{
		"saghen/blink.cmp",
		event = "VimEnter",
		version = "1.*",
		opts = {
			keymap = { preset = "default" },
			appearance = { nerd_font_variant = "mono" },
			completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
			sources = { default = { "lsp", "path", "snippets" } },
			snippets = { preset = "default" },
			fuzzy = { implementation = "lua" },
			signature = { enabled = true },
		},
	},
	{
		"nvim-mini/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup()
			local statusline = require("mini.statusline")
			statusline.setup({ use_icons = vim.g.have_nerd_font })
			statusline.section_location = function()
				return "%2l:%-2v"
			end
		end,
	},
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			require("tokyonight").setup({ styles = { comments = { italic = false } } })
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},
}, {
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
	checker = { enabled = false },
	change_detection = { notify = false },
})
