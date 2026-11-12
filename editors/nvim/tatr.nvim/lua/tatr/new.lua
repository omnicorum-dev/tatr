-- `tatr new` with optional interactive prompts for tags/priority.

local util = require("tatr.util")
local config = require("tatr.config")

local M = {}

local function open_created_task(lines, root)
  if not root then
    return
  end
  local path = lines[1] and lines[1]:match("^(.-):%d+:")
  if not path then
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(util.abspath(path, root)))
end

--- @param opts table|nil
---   title:    string|nil   task title (prompted for if omitted)
---   tags:     string|nil   comma/space separated tags (prompted for
---                          unless prompt_for_tags = false, in which
---                          case no tags are added)
---   priority: string|number|nil  (prompted for unless
---                          prompt_for_priority = false, in which case
---                          tatr's own default priority is used)
function M.new(opts)
  opts = opts or {}

  local function run_new(title, tags, priority)
    local args = { "new" }

    if tags and tags ~= "" then
      for tag in tags:gmatch("[^,%s]+") do
        table.insert(args, "-t")
        table.insert(args, tag)
      end
    end

    if priority ~= nil and tostring(priority) ~= "" then
      table.insert(args, "-p")
      table.insert(args, tostring(priority))
    end

    if title and title ~= "" then
      table.insert(args, title)
    end

    local ok, lines, _, root = util.run(args)
    if not ok then
      return
    end

    vim.notify("tatr.nvim: " .. (lines[1] or "task created"), vim.log.levels.INFO)

    if config.options.open_new_task then
      open_created_task(lines, root)
    end
  end

  local function ask_priority(title, tags)
    if opts.priority ~= nil then
      run_new(title, tags, opts.priority)
    elseif config.options.prompt_for_priority then
      vim.ui.input(
        { prompt = "Priority: ", default = tostring(config.options.default_priority) },
        function(priority)
          if priority == nil then
            return -- cancelled
          end
          run_new(title, tags, priority)
        end
      )
    else
      run_new(title, tags, nil)
    end
  end

  local function ask_tags(title)
    if opts.tags ~= nil then
      ask_priority(title, opts.tags)
    elseif config.options.prompt_for_tags then
      vim.ui.input({ prompt = "Tags (comma separated): " }, function(tags)
        if tags == nil then
          return -- cancelled
        end
        ask_priority(title, tags)
      end)
    else
      ask_priority(title, nil)
    end
  end

  if opts.title and opts.title ~= "" then
    ask_tags(opts.title)
  else
    vim.ui.input({ prompt = "Task title: " }, function(title)
      if title == nil then
        return -- cancelled
      end
      ask_tags(vim.trim(title))
    end)
  end
end

return M
