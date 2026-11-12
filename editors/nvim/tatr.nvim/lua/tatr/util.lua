-- Shared helpers for shelling out to `tatr`.

local config = require("tatr.config")

local M = {}

-- A HUID looks like [0-9]{8}-[0-9]{6}(-[a-zA-Z0-9-]*)? (see src/huid.h).
local HUID_PATTERN = "%d%d%d%d%d%d%d%d%-%d%d%d%d%d%d[%w%-]*"

--- True if `str` is (entirely) a validly-shaped HUID.
function M.is_huid(str)
  return str ~= nil and str:match("^" .. HUID_PATTERN .. "$") ~= nil
end

--- Find a HUID-shaped token under the cursor in the current line, if any.
function M.huid_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed
  local from = 1
  while true do
    local s, e = line:find(HUID_PATTERN, from)
    if not s then
      return nil
    end
    if col >= s and col <= e then
      return line:sub(s, e)
    end
    from = e + 1
  end
end

--- The HUID of the task folder the current buffer lives directly inside
--- of, if any -- true when editing that task's TASK.md, or any other
--- file next to it, since the folder itself is named after the HUID.
function M.huid_from_buffer_dir()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return nil
  end
  local dirname = vim.fs.basename(vim.fs.dirname(bufname))
  return M.is_huid(dirname) and dirname or nil
end

--- "The HUID we're talking about" from context: the one under the
--- cursor, else the current buffer's own task folder.
function M.current_huid()
  return M.huid_under_cursor() or M.huid_from_buffer_dir()
end

--- Resolve the directory `tatr` should be run from.
--- tatr searches upward from this directory for a tasks/ folder, so any
--- directory inside the project (including inside a task's own folder)
--- resolves correctly.
function M.root_dir()
  local root = config.options.root

  if type(root) == "function" then
    local ok, dir = pcall(root)
    if ok and dir and dir ~= "" then
      return dir
    end
    return vim.loop.cwd()
  end

  if root == "buffer" then
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname ~= "" then
      return vim.fs.dirname(bufname)
    end
  end

  return vim.loop.cwd()
end

--- Make `path` absolute by joining it onto `root` if it isn't already.
function M.abspath(path, root)
  if vim.startswith(path, "/") then
    return path
  end
  return vim.fs.joinpath(root, path)
end

--- Run `tatr <args>` synchronously.
--- Returns: ok (boolean), stdout_lines (string[]), stderr (string), root (string)
function M.run(args)
  if vim.fn.executable(config.options.cmd) == 0 then
    vim.notify(
      ("tatr.nvim: `%s` not found on $PATH (see :checkhealth tatr)"):format(config.options.cmd),
      vim.log.levels.ERROR
    )
    return false, {}, "", nil
  end

  local root = M.root_dir()

  local cmd = { config.options.cmd }
  vim.list_extend(cmd, args)

  local ok_call, result = pcall(function()
    return vim.system(cmd, { cwd = root, text = true }):wait()
  end)

  if not ok_call then
    vim.notify("tatr.nvim: failed to run `" .. table.concat(cmd, " ") .. "`: " .. tostring(result), vim.log.levels.ERROR)
    return false, {}, "", root
  end

  local stdout_lines = {}
  if result.stdout and result.stdout ~= "" then
    stdout_lines = vim.split(result.stdout, "\n", { trimempty = true })
  end

  if result.code ~= 0 then
    local msg = vim.trim(result.stderr or "")
    if msg == "" then
      msg = ("`%s` exited with code %d"):format(table.concat(cmd, " "), result.code)
    end
    vim.notify("tatr.nvim: " .. msg, vim.log.levels.ERROR)
    return false, stdout_lines, result.stderr or "", root
  end

  return true, stdout_lines, result.stderr or "", root
end

return M
