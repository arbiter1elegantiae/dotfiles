local ok, err = pcall(function()
  assert(vim.v.errmsg == "", "Startup error: " .. vim.v.errmsg)
  assert(not vim.opt.relativenumber:get(), "Relative numbers override not loaded")
  assert(vim.g.autoformat == false, "Autoformat override not loaded")
  assert(vim.g.colors_name == "tokyonight-night", "Fallback theme not loaded")

  local lock = vim.json.decode(table.concat(vim.fn.readfile(vim.env.HOME .. "/expected-lazy-lock.json"), "\n"))
  local plugins = require("lazy.core.config").plugins
  for name, revision in pairs(lock) do
    assert(plugins[name], "Locked plugin is missing from the configuration: " .. name)
    local head = vim.fn.system({ "git", "-C", plugins[name].dir, "rev-parse", "HEAD" }):gsub("%s+$", "")
    assert(vim.v.shell_error == 0 and head == revision.commit, "Plugin revision mismatch: " .. name)
    for _, task in ipairs(plugins[name]._.tasks or {}) do
      assert(not task:has_errors(), "Plugin installation task failed: " .. name)
    end
  end

  local project = vim.env.HOME .. "/smoke-project"
  vim.cmd.edit(project .. "/example.lua")
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  assert(require("blink.cmp").get_lsp_capabilities().textDocument.completion, "Completion capabilities missing")
  assert(require("neo-tree"), "File explorer cannot load")
  assert(vim.wait(10000, function() return vim.b.gitsigns_head ~= nil end, 100), "Git signs did not attach")
  assert(vim.wait(120000, function()
    return pcall(vim.treesitter.language.add, "lua")
  end, 100), "Lua Tree-sitter parser did not install")
  local tree = vim.treesitter.get_parser(0, "lua"):parse()[1]
  assert(tree and not tree:root():has_error(), "Tree-sitter cannot parse a Lua buffer")

  local format_err
  require("conform").format({ formatters = { "stylua" }, async = false, timeout_ms = 10000 }, function(error)
    format_err = error
  end)
  assert(not format_err, "Formatting failed: " .. tostring(format_err))
  assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "local value = { 1, 2, 3 }", "StyLua did not format the buffer")

  -- Start the installed server directly: this must work without a Mason download.
  local client_id = vim.lsp.start({
    name = "smoke-lua",
    cmd = { "lua-language-server" },
    root_dir = project,
  })
  assert(client_id, "Lua language server did not start")
  assert(vim.wait(30000, function()
    local client = vim.lsp.get_client_by_id(client_id)
    return client and client.initialized
  end, 100), "Lua language server did not initialize")
  local client = vim.lsp.get_client_by_id(client_id)
  local response = client:request_sync("textDocument/documentSymbol", {
    textDocument = { uri = vim.uri_from_bufnr(0) },
  }, 10000, 0)
  assert(response and not response.err and response.result, "LSP document symbols request failed")
  client:stop(true)

  -- Simulate Omarchy changing its generated theme, without a desktop session.
  local theme = (vim.env.XDG_STATE_HOME or vim.env.HOME .. "/.local/state") .. "/omarchy/current/theme"
  vim.fn.mkdir(theme, "p")
  vim.fn.writefile({
    'return { { "folke/tokyonight.nvim", priority = 1000 },',
    '{ "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-day" } } }',
  }, theme .. "/neovim.lua")
  assert(vim.wait(5000, function() return vim.g.colors_name == "tokyonight-day" end, 50), "Theme hot reload failed")

  vim.env.SSH_CONNECTION = "smoke"
  require("config.remote_clipboard").setup()
  assert(vim.g.clipboard.name == "OmarchyRemoteClipboard", "Remote clipboard provider not selected")
  assert(type(vim.g.clipboard.copy["+"]) == "function", "Remote copy handler missing")
  assert(type(vim.g.clipboard.paste["+"]) == "function", "Remote paste handler missing")
  assert(vim.v.errmsg == "", "Neovim error: " .. vim.v.errmsg)
end)

if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
else
  print("Neovim smoke tests passed")
  vim.cmd("qa!")
end
