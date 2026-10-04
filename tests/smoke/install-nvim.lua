local ok, err = pcall(function()
  assert(vim.v.errmsg == "", "First-startup error: " .. vim.v.errmsg)
  local config = require("lazy.core.config")
  for name, plugin in pairs(config.plugins) do
    for _, task in ipairs(plugin._.tasks or {}) do
      assert(not task:has_errors(), "Plugin installation failed: " .. name)
    end
  end

  -- Parser installation is asynchronous. Let all configured builds finish
  -- before quitting, so a subsequent editor does not race orphaned compilers.
  local parsers = require("lazy.core.plugin").values(config.plugins["nvim-treesitter"], "opts", false).ensure_installed
  local revision_dir = require("nvim-treesitter.config").get_install_dir("parser-info")
  assert(vim.wait(180000, function()
    local installed = require("nvim-treesitter").get_installed("parsers")
    for _, parser in ipairs(parsers) do
      if not vim.tbl_contains(installed, parser) then
        return false
      end
      local info = require("nvim-treesitter.parsers")[parser].install_info
      if info and info.revision and vim.fn.filereadable(revision_dir .. "/" .. parser .. ".revision") ~= 1 then
        return false
      end
    end
    return true
  end, 100), "Configured Tree-sitter parsers did not finish installing")
  -- Existing parser files can still belong to a previous plugin revision.
  -- The public update task joins in-progress builds and reports failures.
  assert(require("nvim-treesitter").update(parsers):wait(180000), "Tree-sitter parser update failed")
  for _, parser in ipairs(parsers) do
    local info = require("nvim-treesitter.parsers")[parser].install_info
    if info and info.revision then
      local installed = vim.fn.readfile(revision_dir .. "/" .. parser .. ".revision")[1]
      assert(installed == info.revision, "Parser revision mismatch: " .. parser)
    end
  end
  assert(vim.v.errmsg == "", "Installation error: " .. vim.v.errmsg)
end)

if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
else
  print("Neovim installation checks passed")
  vim.cmd("qa!")
end
