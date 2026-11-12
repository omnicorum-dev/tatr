-- tatr.nvim: a thin Neovim wrapper around the `tatr` CLI
-- (https://github.com/tsoding/tatr).
--
-- This plugin is intentionally kept outside of tatr's own C source tree:
-- it only shells out to the `tatr` binary and never touches the project
-- it wraps.

local M = {}

--- @param opts table|nil  see lua/tatr/config.lua for available options
function M.setup(opts)
  require("tatr.config").setup(opts)
end

--- List tasks into the quickfix list.
--- @param args string[]|nil  raw arguments forwarded to `tatr ls`
function M.ls(args)
  require("tatr.ls").ls(args)
end

--- Create a new task, prompting for any missing details.
--- @param opts table|nil  see lua/tatr/new.lua
function M.new(opts)
  require("tatr.new").new(opts)
end

--- Open the snacks.nvim task browser/picker (requires folke/snacks.nvim).
--- @param opts table|nil  { closed?: boolean } -- see lua/tatr/picker.lua
function M.pick(opts)
  require("tatr.picker").ls(opts)
end

--- Show a summary of tasks (counts per tag) in a floating window.
--- @param opts table|nil  { closed?: boolean }
function M.summary(opts)
  require("tatr.summary").summary(opts)
end

--- Find referers of a task into the quickfix list.
--- @param opts table|nil  see lua/tatr/ref.lua
function M.ref(opts)
  require("tatr.ref").ref(opts)
end

--- Look up a task by HUID and jump straight to its TASK.md.
--- @param opts table|nil  { huid?: string } -- see lua/tatr/find.lua
function M.find(opts)
  require("tatr.find").find(opts)
end

--- Copy a task's HUID to the system clipboard.
--- @param opts table|nil  { huid?: string } -- see lua/tatr/yank.lua
function M.yank(opts)
  require("tatr.yank").yank(opts)
end

return M
