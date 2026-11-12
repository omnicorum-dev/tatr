-- Copy a task's HUID to the system clipboard. Pure Lua -- doesn't need to
-- shell out to `tatr` at all, since the HUID is just the task folder's
-- name.

local util = require("tatr.util")

local M = {}

--- @param opts table|nil  { huid?: string }
---   huid: string|nil  defaults to `util.current_huid()`: the HUID under
---     the cursor, or (failing that) the current buffer's own task
---     folder -- i.e. this works both while editing a task's TASK.md and
---     while looking at a reference to one elsewhere.
function M.yank(opts)
  opts = opts or {}
  local huid = opts.huid or util.current_huid()

  if not huid then
    vim.notify(
      "tatr.nvim: no task HUID found here (not on one, and not inside a task folder)",
      vim.log.levels.WARN
    )
    return
  end

  vim.fn.setreg("+", huid)
  vim.notify("tatr.nvim: copied `" .. huid .. "` to the clipboard", vim.log.levels.INFO)
end

return M
