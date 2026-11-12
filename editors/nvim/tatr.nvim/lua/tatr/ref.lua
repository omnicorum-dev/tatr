-- `tatr ref` -> quickfix list.
--
-- Like `ls.lua`, this piggybacks on the fact that `tatr ref` is just a
-- `grep -rn` under the hood (see `ref_run` in src/tatr.c), so its output
-- is already in the same grep/compile format we feed to the quickfix
-- list via 'errorformat'.

local util = require("tatr.util")
local config = require("tatr.config")

local M = {}

local EFM = "%f:%l:%m"

--- Find referers of a task: everywhere in the project (outside .git) that
--- mentions its HUID.
--- @param opts table|nil
---   huid: string|nil  defaults to the HUID under the cursor, and failing
---     that lets `tatr ref` fall back to its own behavior: if the current
---     buffer's directory *is* a task's own folder (e.g. you're editing
---     that task's TASK.md), it figures out the HUID from the directory
---     name itself.
function M.ref(opts)
  opts = opts or {}
  local huid = opts.huid or util.huid_under_cursor()

  local args = { "ref" }
  if huid then
    table.insert(args, huid)
  end

  local ok, lines, _, root = util.run(args)
  if not ok then
    return
  end

  if #lines == 0 then
    vim.notify("tatr.nvim: no references found", vim.log.levels.INFO)
    vim.fn.setqflist({}, "r", { title = "tatr ref " .. (huid or ""), items = {} })
    return
  end

  -- Same cwd-relative -> absolute rewrite as ls.lua, for the same reason.
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
    title = "tatr ref " .. (huid or ""),
    lines = abs_lines,
    efm = EFM,
  })

  if config.options.open_quickfix then
    vim.cmd("copen")
  end
end

return M
