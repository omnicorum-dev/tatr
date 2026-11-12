-- tatr.nvim configuration.
--
-- New file, part of the (unofficial) editors/nvim/tatr.nvim plugin.
-- Does not modify anything in tatr's own source tree.

local M = {}

M.defaults = {
  -- Name or path of the tatr executable.
  cmd = "tatr",

  -- How to pick the working directory tatr is run from. tatr walks
  -- upward from there looking for a tasks/ folder (see `tatr help`),
  -- so any directory inside the project works.
  --   "buffer"   - directory of the current buffer's file (default)
  --   "cwd"      - Neovim's current working directory
  --   function   - custom function() -> string|nil
  root = "buffer",

  -- Open the quickfix window after a successful :TatrLs.
  open_quickfix = true,

  -- Ask for tags / priority when :TatrNew is run without them already
  -- supplied. Set to false to always use the tool's own defaults
  -- (no tags, priority 100) without prompting.
  prompt_for_tags = true,
  prompt_for_priority = true,
  default_priority = 100,

  -- Open the newly created task's TASK.md after :TatrNew.
  open_new_task = true,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
