-- Override the snacks.nvim file explorer (LazyVim's default, opened with <leader>e).
-- By default `y` copies the *absolute* path linewise (trailing newline). Here:
--   y     -> copy path relative to the explorer root
--   Y     -> copy absolute path
--   <c-v> -> save a clipboard image into the directory under the cursor
-- Yanks copy to the system clipboard charwise (no trailing newline) and
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

-- Save a clipboard image (e.g. a screenshot) as a file in the directory under
-- the cursor. Reuses img-clip's clipboard backends (pngpaste on macOS,
-- xclip/wl-paste on Linux) without its markdown-markup insertion, and mirrors
-- the prompt + tree-refresh flow of snacks' own explorer_add action.
local function paste_image(picker)
  local clipboard = require("img-clip.clipboard")
  if not clipboard.get_clip_cmd() then
    return Snacks.notify.error("No clipboard command found. See :checkhealth img-clip.")
  end
  if not clipboard.content_is_image() then
    return Snacks.notify.warn("Clipboard does not contain an image")
  end
  local dir = picker:dir()
  Snacks.input({
    prompt = "Save clipboard image as",
    default = os.date("%Y-%m-%d-%H%M%S") .. ".png",
  }, function(name)
    if not name or name:find("^%s*$") then
      return
    end
    if not name:match("%.%w+$") then
      name = name .. ".png"
    end
    local path = vim.fs.normalize(dir .. "/" .. name)
    if (vim.uv or vim.loop).fs_stat(path) then
      return Snacks.notify.error("File already exists: " .. path)
    end
    if not clipboard.save_image(path) then
      return Snacks.notify.error("Could not save clipboard image")
    end
    local Tree = require("snacks.explorer.tree")
    Tree:refresh(dir)
    Tree:open(dir)
    require("snacks.explorer.actions").update(picker, { target = path })
    Snacks.notify.info("Saved " .. name)
  end)
end

return {
  "folke/snacks.nvim",
  opts = {
    -- Render image files (and inline markdown images) in the buffer via the
    -- Kitty graphics protocol instead of showing raw bytes. Works because the
    -- outer terminal is Ghostty (speaks the protocol) and tmux is told to pass
    -- the escapes through (`allow-passthrough on` in dot_tmux.conf). Needs the
    -- `magick` CLI (ImageMagick) on PATH — see the package scripts. Just open a
    -- .png/.jpg/.svg/.pdf/… and it displays; :checkhealth snacks reports status.
    image = { enabled = true },
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
        explorer_paste_image = paste_image,
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
                ["<c-v>"] = "explorer_paste_image",
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
