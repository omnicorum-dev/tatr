local M = {}

function M.check()
  vim.health.start("tatr.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10 (vim.system available)")
  else
    vim.health.error("tatr.nvim requires Neovim >= 0.10 (needs vim.system())")
  end

  local config = require("tatr.config")
  local cmd = config.options.cmd

  if vim.fn.executable(cmd) == 1 then
    vim.health.ok(("`%s` found on $PATH"):format(cmd))
  else
    vim.health.error(("`%s` not found on $PATH"):format(cmd), {
      "Build/install tatr and make sure it's on $PATH, or point tatr.nvim at it:",
      "require('tatr').setup({ cmd = '/path/to/tatr' })",
    })
  end
end

return M
