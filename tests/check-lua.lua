local ok, err = pcall(function()
  for _, path in ipairs(vim.fn.glob("nvim/**/*.lua", false, true)) do
    assert(loadfile(path))
  end
  for _, path in ipairs(vim.fn.glob("tests/smoke/*.lua", false, true)) do
    assert(loadfile(path))
  end
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
else
  print("Lua syntax checks passed")
  vim.cmd("qa!")
end
