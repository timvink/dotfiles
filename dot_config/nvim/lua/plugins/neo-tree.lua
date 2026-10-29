-- Keep Omarchy's Neo-tree finder behavior: / searches names, D searches only
-- directories, Shift+Enter keeps the filter, and h / z collapse filtered nodes.
-- Finder patterns are globs (dot_*), not regexes or paths ending in /.
local function yank(state, relative, nodes)
  local current = state.tree:get_node()
  nodes = nodes or { current }
  local files = {}
  for _, node in ipairs(nodes) do
    local path = node:get_id()
    if node.type == "file" or node.type == "directory" then
      if relative and path:sub(1, #state.path + 1) == state.path .. "/" then
        path = path:sub(#state.path + 2)
      end
      files[#files + 1] = path
    end
  end
  vim.fn.setreg(vim.v.register or "+", table.concat(files, "\n"), "c")
  Snacks.notify.info("Yanked " .. #files .. " " .. (relative and "relative" or "absolute") .. " path(s)")
end

local function paste_image(state)
  local clipboard = require("img-clip.clipboard")
  if not clipboard.get_clip_cmd() then
    return Snacks.notify.error("No clipboard command found. See :checkhealth img-clip.")
  end
  if not clipboard.content_is_image() then
    return Snacks.notify.warn("Clipboard does not contain an image")
  end
  local node = state.tree:get_node()
  local dir = node.type == "directory" and node:get_id() or vim.fs.dirname(node:get_id())
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
    -- A directory-only filter would hide the new image; reveal it in the tree.
    require("neo-tree.sources.filesystem").reset_search(state, false)
    require("neo-tree.command").execute({ source = "filesystem", action = "focus", reveal_file = path })
    Snacks.notify.info("Saved " .. name)
  end)
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    commands = {
      yank_relative = function(state)
        yank(state, true)
      end,
      yank_relative_visual = function(state, nodes)
        yank(state, true, nodes)
      end,
      yank_absolute = function(state)
        yank(state, false)
      end,
      yank_absolute_visual = function(state, nodes)
        yank(state, false, nodes)
      end,
      paste_image = paste_image,
    },
    window = {
      mappings = {
        ["y"] = "yank_relative",
        ["Y"] = "yank_absolute",
        ["<C-v>"] = "paste_image",
      },
    },
  },
}
