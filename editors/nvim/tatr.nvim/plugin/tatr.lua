if vim.g.loaded_tatr then
  return
end
vim.g.loaded_tatr = true

local tql_completion = {
  "-c", "-a", "-id", "-debug",
  "and", "or", "not", "any", "tagged", "priority",
  "lt", "le", "gt", "ge", "eq", "ne",
}

local function tql_complete(arglead)
  return vim.tbl_filter(function(candidate)
    return vim.startswith(candidate, arglead)
  end, tql_completion)
end

vim.api.nvim_create_user_command("TatrLs", function(cmd_opts)
  require("tatr").ls(cmd_opts.fargs)
end, {
  nargs = "*",
  complete = function(arglead)
    return tql_complete(arglead)
  end,
  desc = "List open tatr tasks into the quickfix list (accepts `tatr ls` flags and a TQL query)",
})

vim.api.nvim_create_user_command("TatrLsClosed", function(cmd_opts)
  local args = { "-c" }
  vim.list_extend(args, cmd_opts.fargs)
  require("tatr").ls(args)
end, {
  nargs = "*",
  complete = function(arglead)
    return tql_complete(arglead)
  end,
  desc = "List closed tatr tasks into the quickfix list",
})

vim.api.nvim_create_user_command("TatrNew", function(cmd_opts)
  local title = table.concat(cmd_opts.fargs, " ")
  require("tatr").new({ title = title ~= "" and title or nil })
end, {
  nargs = "*",
  desc = "Create a new tatr task (prompts for anything not supplied)",
})

vim.api.nvim_create_user_command("TatrPick", function()
  require("tatr").pick()
end, {
  desc = "Fuzzy-search open tatr tasks in a snacks.nvim picker (list + TASK.md preview)",
})

vim.api.nvim_create_user_command("TatrPickClosed", function()
  require("tatr").pick({ closed = true })
end, {
  desc = "Fuzzy-search closed tatr tasks in a snacks.nvim picker (list + TASK.md preview)",
})

vim.api.nvim_create_user_command("TatrPickQuery", function()
  require("tatr").pick({ live = true })
end, {
  desc = "Browse open tatr tasks in a snacks.nvim picker, typing a live TQL query (like `tatr ls`)",
})

vim.api.nvim_create_user_command("TatrPickQueryClosed", function()
  require("tatr").pick({ closed = true, live = true })
end, {
  desc = "Browse closed tatr tasks in a snacks.nvim picker, typing a live TQL query (like `tatr ls -c`)",
})

vim.api.nvim_create_user_command("TatrSummary", function()
  require("tatr").summary()
end, {
  desc = "Show a summary of open tatr tasks (counts per tag) in a floating window",
})

vim.api.nvim_create_user_command("TatrSummaryClosed", function()
  require("tatr").summary({ closed = true })
end, {
  desc = "Show a summary of closed tatr tasks (counts per tag) in a floating window",
})

vim.api.nvim_create_user_command("TatrRef", function(cmd_opts)
  require("tatr").ref({ huid = cmd_opts.args ~= "" and cmd_opts.args or nil })
end, {
  nargs = "?",
  desc = "Find references to a tatr task into the quickfix list (HUID under cursor, "
    .. "current task folder, or a HUID given explicitly)",
})

vim.api.nvim_create_user_command("TatrFind", function(cmd_opts)
  require("tatr").find({ huid = cmd_opts.args ~= "" and cmd_opts.args or nil })
end, {
  nargs = "?",
  desc = "Look up a tatr task by HUID and jump straight to its TASK.md",
})

vim.api.nvim_create_user_command("TatrYank", function(cmd_opts)
  require("tatr").yank({ huid = cmd_opts.args ~= "" and cmd_opts.args or nil })
end, {
  nargs = "?",
  desc = "Copy a tatr task's HUID to the clipboard (HUID under cursor, or current task folder)",
})
