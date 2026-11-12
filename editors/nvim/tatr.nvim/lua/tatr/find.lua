-- `tatr find <HUID> -path-only` -> jump straight to that task's TASK.md.

local util = require("tatr.util")

local M = {}

--- @param opts table|nil  { huid?: string }
function M.find(opts)
  opts = opts or {}

  local function go(huid)
    if huid == nil then
      return -- cancelled
    end
    huid = vim.trim(huid)
    if huid == "" then
      return
    end

    local ok, lines, _, root = util.run({ "find", huid, "-path-only" })
    if not ok then
      return
    end

    local path = lines[1]
    if not path or path == "" then
      vim.notify("tatr.nvim: no task found for `" .. huid .. "`", vim.log.levels.WARN)
      return
    end

    vim.cmd.edit(vim.fn.fnameescape(util.abspath(path, root)))
  end

  if opts.huid and opts.huid ~= "" then
    go(opts.huid)
  else
    vim.ui.input({ prompt = "Task HUID: ", default = util.current_huid() or "" }, go)
  end
end

return M
