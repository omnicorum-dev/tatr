-- `tatr ls` -> quickfix list.
--
-- tatr's own task listing is already in a grep/compile-friendly format
-- (see `print_task` in src/task.c: "<path>/TASK.md:1: STATUS ..."), so we
-- just feed its stdout straight into the quickfix list using that shape
-- as an 'errorformat'.

local util = require("tatr.util")
local config = require("tatr.config")

local M = {}

local EFM = "%f:%l:%m"

--- @param args string[]|nil  extra arguments forwarded to `tatr ls`
---   (tatr's own flags like -c/-a/-id, and/or a TQL query, e.g.
---   { ":bug", "and", "not", ":ui" })
function M.ls(args)
  args = args or {}

  local cmd = { "ls" }
  vim.list_extend(cmd, args)

  local ok, lines, _, root = util.run(cmd)
  if not ok then
    return
  end

  local title = "tatr ls " .. table.concat(args, " ")

  if #lines == 0 or lines[1]:match("^No tasks were found") then
    vim.notify("tatr.nvim: no tasks found", vim.log.levels.INFO)
    vim.fn.setqflist({}, "r", { title = title, items = {} })
    return
  end

  -- Rewrite the (tatr-cwd-relative) paths to absolute ones so the
  -- quickfix list opens the right file no matter what Neovim's own
  -- current working directory is.
  local abs_lines = {}
  for _, line in ipairs(lines) do
    local path, rest = line:match("^(.-):(%d+:.*)$")
    if path and root then
      table.insert(abs_lines, util.abspath(path, root) .. ":" .. rest)
    else
      table.insert(abs_lines, line)
    end
  end

  vim.fn.setqflist({}, " ", {
    title = title,
    lines = abs_lines,
    efm = EFM,
  })

  if config.options.open_quickfix then
    vim.cmd("copen")
  end
end

return M
