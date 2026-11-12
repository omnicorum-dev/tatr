-- `tatr summary` shown in a small floating scratch window.
--
-- Unlike `ls`/`ref`, `tatr summary`'s output isn't in a file:line:message
-- shape, so there's nothing sensible to put in the quickfix list -- it's
-- just read, not something to jump from.

local util = require("tatr.util")

local M = {}

--- @param opts table|nil  { closed?: boolean }
function M.summary(opts)
  opts = opts or {}
  local args = { "summary" }
  if opts.closed then
    table.insert(args, "-c")
  end

  local ok, lines = util.run(args)
  if not ok then
    return
  end
  if #lines == 0 then
    lines = { "(no output)" }
  end

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.max(math.min(width + 2, math.floor(vim.o.columns * 0.8)), 30)
  local height = math.min(#lines, math.floor(vim.o.lines * 0.8))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "tatr-summary"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = opts.closed and " Tatr Summary (closed) " or " Tatr Summary ",
    title_pos = "center",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  for _, lhs in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", lhs, close, { buffer = buf, nowait = true, silent = true })
  end
  vim.api.nvim_create_autocmd("BufLeave", { buffer = buf, once = true, callback = close })
end

return M
