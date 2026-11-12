# tatr.nvim

An (unofficial) Neovim wrapper around [`tatr`](../../..), the command-line
task tracker this plugin lives next to. It only shells out to the `tatr`
binary — it doesn't touch tatr's own source at all, so it's safe to update
independently.

Requires Neovim >= 0.10 (uses `vim.system`) and a `tatr` binary. The task
browser additionally requires [snacks.nvim](https://github.com/folke/snacks.nvim)
(everything else works fine without it).

## Install (lazy.nvim)

Point lazy.nvim at this directory (it's a subfolder of the `tatr` repo, not
a repo of its own), e.g. if you've cloned `tatr` to `~/dev/tatr`:

```lua
{
  dir = "~/dev/tatr/editors/nvim/tatr.nvim",
  dependencies = { "folke/snacks.nvim" }, -- only needed for :TatrPick*
  cmd = {
    "TatrLs", "TatrLsClosed", "TatrNew",
    "TatrPick", "TatrPickClosed", "TatrPickQuery", "TatrPickQueryClosed",
    "TatrSummary", "TatrSummaryClosed", "TatrRef", "TatrFind", "TatrYank",
  },
  keys = {
    { "<leader>ts", function() require("tatr").pick() end, desc = "Tatr: Search Tasks" },
    { "<leader>tl", function() require("tatr").pick({ live = true }) end, desc = "Tatr: Query Tasks (TQL)" },
    { "<leader>tc", function() require("tatr").pick({ closed = true }) end, desc = "Tatr: Search Closed Tasks" },
    { "<leader>tn", function() require("tatr").new() end, desc = "Tatr: New Task" },
    { "<leader>ta", function() require("tatr").summary() end, desc = "Tatr: Summary" },
    { "<leader>tr", function() require("tatr").ref() end, desc = "Tatr: References" },
    { "<leader>tf", function() require("tatr").find() end, desc = "Tatr: Find (jump to HUID)" },
    { "<leader>tx", function() require("tatr").yank() end, desc = "Tatr: Yank HUID" },
  },
  opts = {
    -- If `tatr` isn't on the $PATH Neovim's process sees (a common
    -- macOS/GUI gotcha -- shows up as "failed to spawn tatr"), point
    -- straight at the binary instead:
    -- cmd = "~/dev/tatr/build/tatr",
  },
}
```

`opts = {}` calls `require("tatr").setup({})`; pass your own table to
override any of the defaults below. If you use which-key, you'll probably
also want to label the group:

```lua
{
  "folke/which-key.nvim",
  optional = true,
  opts = { spec = { { "<leader>t", group = "tatr" } } },
}
```

## Task browser: `:TatrPick*` (`<leader>ts` / `<leader>tl` / `<leader>tc`)

A [snacks.nvim](https://github.com/folke/snacks.nvim) picker, in the same
spirit as `Snacks.picker.git_log()`: a list on one side, a live preview of
the selected task's `TASK.md` on the other.

- `:TatrPick` (`<leader>ts`, "**s**earch") — opens showing every open task
  in `tatr ls`'s own order. Typing fuzzy-filters that list locally against
  title/tags/status/id, just like typing in the git log picker.
  `:TatrPickClosed` (`<leader>tc`) is the same for closed tasks.
- `:TatrPickQuery` (`<leader>tl`, "t**q**l"... well, "**l**s") — opens the
  same picker already in snacks' **live** mode: the input box is a real
  `tatr ls` TQL query from the start, re-run on every keystroke, e.g.
  `:bug and not :ui` or `priority lt 50`. `:TatrPickQueryClosed` is the
  closed-task equivalent. (You can also get to live mode from a fuzzy
  picker at any time with `<c-g>`, and back with `<c-g>` again.)
- `<CR>` jumps straight to that task's `TASK.md` in either mode.
- `x` copies the HUID of the task under the cursor to the system clipboard
  (register `+`), in both fuzzy and live/TQL mode.

## Other commands

- `:TatrLs [flags/query...]` — runs `tatr ls` and loads the results into
  the quickfix list instead (no snacks.nvim needed). Since tatr already
  prints tasks in a `path/TASK.md:1: ...` (grep/compile) format, entries
  jump straight to the task's `TASK.md`. Accepts anything `tatr ls` does:

  ```vim
  :TatrLs
  :TatrLs -a -id
  :TatrLs :bug and not :ui
  :TatrLs priority lt 50
  ```

  `:TatrLsClosed [query...]` is shorthand for `:TatrLs -c ...`.

- `:TatrNew [title...]` (`<leader>tn`) — creates a new task. If no title is
  given on the command line you're prompted for one, then (unless
  disabled, see below) prompted for tags and a priority. The new
  `TASK.md` is opened afterwards.

  ```vim
  :TatrNew Fix the login bug
  ```

- `:TatrSummary` (`<leader>ta`) — shows `tatr summary`'s tag/priority
  breakdown for open tasks in a small floating window (`q` or `<Esc>` to
  close). `:TatrSummaryClosed` is the closed-task equivalent.

- `:TatrRef [huid]` (`<leader>tr`) — finds every place in the project that
  mentions a task's HUID (it's just `tatr ref`, i.e. a `grep -rn` under
  the hood, so results load straight into the quickfix list). With no
  argument it uses the HUID under the cursor if there is one; otherwise
  it falls back to `tatr ref`'s own behavior of figuring out the HUID
  from the current directory when you're editing that task's own
  `TASK.md`.

- `:TatrFind [huid]` (`<leader>tf`) — looks up a task by HUID (`tatr find
  <huid> -path-only`) and jumps straight to its `TASK.md`. With no
  argument you're prompted, prefilled with the HUID under the cursor or
  (failing that) the current buffer's own task folder, if either is
  available.

- `:TatrYank [huid]` (`<leader>tx`) — copies a task's HUID to the system
  clipboard (register `+`). Pure Lua, no `tatr` call needed. With no
  argument, uses the HUID under the cursor, or (failing that) the current
  buffer's own task folder — so it works both while browsing a reference
  to a task and while sitting inside that task's own folder.

## Configuration

```lua
require("tatr").setup({
  cmd = "tatr",              -- executable name or full path

  -- Working directory tatr is run from; it searches upward from here
  -- for a tasks/ folder, so anywhere inside the project works.
  --   "buffer"   - directory of the current buffer's file (default)
  --   "cwd"      - Neovim's current working directory
  --   function() -> string|nil
  root = "buffer",

  open_quickfix = true,        -- :copen after a successful :TatrLs/:TatrRef

  prompt_for_tags = true,      -- ask for tags on :TatrNew
  prompt_for_priority = true,  -- ask for priority on :TatrNew
  default_priority = 100,      -- suggested default in the priority prompt
  open_new_task = true,        -- open TASK.md after :TatrNew
})
```

## Health check

`:checkhealth tatr` verifies Neovim's version and that `tatr` is
reachable.

## Extending

`lua/tatr/ls.lua`, `lua/tatr/new.lua`, `lua/tatr/summary.lua`,
`lua/tatr/ref.lua`, `lua/tatr/find.lua` and `lua/tatr/picker.lua` are all
small and self-contained, built on the same `util.run(args)` helper —
`tatr graph` follows the same pattern if you want to add commands of your
own. `lua/tatr/yank.lua` and the HUID helpers in `lua/tatr/util.lua`
(`current_huid`, `huid_under_cursor`, `huid_from_buffer_dir`) are handy if
you want more HUID-aware commands.
