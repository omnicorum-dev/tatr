-- A snacks.nvim (https://github.com/folke/snacks.nvim) picker for browsing
-- tatr tasks, in the same spirit as e.g. `Snacks.picker.git_log()`:
--   - opens showing every (open, or closed with `{ closed = true }`) task,
--     sorted the way `tatr ls` sorts them
--   - typing fuzzy-filters that list locally (fast, like any other picker)
--   - <c-g> toggles "live" mode (built into snacks, see `supports_live`
--     below): once live, whatever you type is sent to `tatr ls` verbatim as
--     a TQL query and re-run on every keystroke, e.g. `:bug and not :ui`
--   - <CR> jumps straight to that task's TASK.md; the preview pane on the
--     right shows the file itself (snacks' builtin "file" previewer)
--
-- This reaches into snacks' `snacks.picker.source.proc` helper, which is
-- the same building block snacks' own `git_log`/`grep` pickers use to
-- stream an external command's stdout into the picker. It's not part of
-- snacks' public docs, so a future snacks release could move it -- if
-- `require("tatr").pick()` ever errors with a "module not found", that's
-- the first place to look.

local util = require("tatr.util")
local config = require("tatr.config")

local M = {}

--- Parse one line of `tatr ls` output (see `print_task` in src/task.c):
---   <dir>/<id>/TASK.md:1: STATUS [PRIORITY: NNN] [tag1,tag2] Title
--- The tags group is only present when the task has tags.
---@param line string
---@return table|nil
local function parse_line(line)
  local path, lnum, rest = line:match("^(.-):(%d+):%s?(.*)$")
  if not path then
    return nil
  end

  local status, rest2 = rest:match("^(%S+)%s*(.*)$")
  status, rest2 = status or rest, rest2 or ""

  local priority, rest3 = rest2:match("^%[PRIORITY:%s*(%-?%d+)%]%s*(.*)$")
  rest3 = rest3 or rest2

  local tags_str, title = rest3:match("^%[([^%]]*)%]%s*(.*)$")
  if not tags_str then
    title = rest3
  end

  local tags = {}
  if tags_str and tags_str ~= "" then
    for tag in tags_str:gmatch("[^,]+") do
      table.insert(tags, tag)
    end
  end

  return {
    path = path,
    line = tonumber(lnum) or 1,
    status = status,
    priority = tonumber(priority),
    tags = tags,
    title = title or "",
    id = path:match("([^/]+)/TASK%.md$"),
  }
end

---@param item table
local function format_item(item)
  local a = Snacks.picker.util.align
  local ret = {} ---@type snacks.picker.Highlight[]

  local closed = item.status == "CLOSED"
  table.insert(ret, { (closed and "󰄬 " or "○ "), closed and "DiagnosticOk" or "DiagnosticWarn" })
  table.insert(ret, { a(item.id or "", 15), "SnacksPickerGitCommit" })
  table.insert(ret, { " " })
  table.insert(ret, { a(tostring(item.priority or 0), 4, { align = "right" }), "SnacksPickerIdx" })
  table.insert(ret, { " " })

  if item.tags and #item.tags > 0 then
    table.insert(ret, { "[" .. table.concat(item.tags, ",") .. "]", "SnacksPickerLabel" })
    table.insert(ret, { " " })
  end

  table.insert(ret, { item.title })
  return ret
end

---@param base_args string[] extra flags always passed to `tatr ls` (e.g. `{ "-c" }`)
---@param root string directory `tatr` is run from
local function make_finder(base_args, root)
  return function(_, ctx)
    local args = { "ls" }
    vim.list_extend(args, base_args)

    if ctx.picker.opts.live then
      local query = vim.trim(ctx.filter.search)
      if query ~= "" then
        vim.list_extend(args, vim.split(query, "%s+"))
      end
    end

    return require("snacks.picker.source.proc").proc({
      cmd = config.options.cmd,
      args = args,
      cwd = root,
      -- Don't spam an error toast while a live TQL query is mid-typing
      -- (e.g. ":bug an") and therefore temporarily invalid -- same
      -- reasoning snacks' own `grep` source uses for search patterns.
      notify = not ctx.picker.opts.live,
      ---@param item snacks.picker.finder.Item
      transform = function(item)
        local parsed = parse_line(item.text)
        if not parsed then
          return false
        end
        item.file = util.abspath(parsed.path, root)
        item.pos = { parsed.line, 0 }
        item.status = parsed.status
        item.priority = parsed.priority or 0
        item.tags = parsed.tags
        item.title = parsed.title
        item.id = parsed.id
        -- What the (non-live) fuzzy matcher searches against.
        item.text = table.concat({
          parsed.title,
          table.concat(parsed.tags, ","),
          parsed.status,
          parsed.id or "",
        }, " ")
      end,
    }, ctx)
  end
end

--- Open the task browser.
---@param opts table|nil  { closed?: boolean, live?: boolean }
---   closed: browse closed tasks instead of open ones
---   live: start in "live" mode, i.e. the input box is a real `tatr ls`
---     TQL query from the start (like pressing <c-g> immediately), rather
---     than a fuzzy filter over the preloaded list.
function M.ls(opts)
  opts = opts or {}
  local base_args = opts.closed and { "-c" } or {}
  local root = util.root_dir()

  local source = "tatr_ls"
  local title = "Tatr Tasks"
  if opts.closed then
    source = source .. "_closed"
    title = "Tatr Closed Tasks"
  end
  if opts.live then
    source = source .. "_live"
    title = title .. " (TQL query)"
  end

  Snacks.picker.pick({
    source = source,
    title = title,
    finder = make_finder(base_args, root),
    format = format_item,
    preview = "file",
    live = opts.live or false,
    supports_live = true,
    -- `x` copies the HUID of the currently highlighted task to the
    -- system clipboard. Bound in both `list` (normal mode, the usual
    -- case once you've navigated there) and `input` (also normal mode
    -- only, e.g. right after <Esc> -- never insert mode, so typing a
    -- literal "x" into a fuzzy/TQL query is untouched).
    actions = {
      tatr_yank_id = { action = "copy", field = "id", reg = "+", desc = "Copy Task HUID" },
    },
    win = {
      list = { keys = { ["x"] = "tatr_yank_id" } },
      input = { keys = { ["x"] = "tatr_yank_id" } },
    },
  })
end

return M
