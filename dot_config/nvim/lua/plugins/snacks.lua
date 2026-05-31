-- Override the snacks.nvim file explorer (LazyVim's default, opened with <leader>e).
-- By default `y` copies the *absolute* path linewise (trailing newline). Here:
--   y  -> copy path relative to the explorer root
--   Y  -> copy absolute path
-- Both copy to the system clipboard charwise (no trailing newline) and
-- support multi-select in visual mode.

-- Yank selected (or hovered) paths to the clipboard, charwise.
local function yank(picker, relative)
  if vim.fn.mode():find("^[vV]") then
    picker.list:select()
  end
  local cwd = picker:cwd()
  local files = {}
  for _, item in ipairs(picker:selected({ fallback = true })) do
    local path = Snacks.picker.util.path(item)
    if path then
      if relative and cwd and path:sub(1, #cwd + 1) == cwd .. "/" then
        path = path:sub(#cwd + 2)
      end
      files[#files + 1] = path
    end
  end
  picker.list:set_selected() -- clear selection
  -- "c" = charwise: no trailing newline (multiple paths still separated by \n).
  vim.fn.setreg(vim.v.register or "+", table.concat(files, "\n"), "c")
  local kind = relative and "relative" or "absolute"
  Snacks.notify.info("Yanked " .. #files .. " " .. kind .. " path(s)")
end

return {
  "folke/snacks.nvim",
  opts = {
    -- Fall back to indent-based scope detection. snacks.scope's async
    -- treesitter parse trips an `attempt to call method 'range' (a nil
    -- value)` crash on BufReadPost under nvim 0.12.2 — the failing
    -- code path is unchanged on snacks' main, so avoid it.
    scope = { treesitter = { enabled = false } },
    picker = {
      actions = {
        explorer_yank_relative = function(picker)
          yank(picker, true)
        end,
        explorer_yank_abs = function(picker)
          yank(picker, false)
        end,
      },
      sources = {
        explorer = {
          hidden = true, -- show dotfiles in the file tree
          ignored = true, -- show gitignored paths too; toggle off in-tree with I
          win = {
            list = {
              keys = {
                ["y"] = { "explorer_yank_relative", mode = { "n", "x" } },
                ["Y"] = { "explorer_yank_abs", mode = { "n", "x" } },
              },
            },
          },
        },
        -- Where the projects picker (dashboard `p`, `<leader>fp`) scans for repos.
        projects = {
          dev = { "~/workspace" },
        },
      },
    },
  },
}
