-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Headless Linux opens links on the Mac through our SSH browser bridge.
-- Default gx kills the opener after one second and discards its fallback URL;
-- the bridge may need three seconds, so run it asynchronously and show output.
local host_opener = vim.fn.expand("~/.local/bin/xdg-open")
if vim.fn.has("linux") == 1
  and not vim.env.DISPLAY
  and not vim.env.WAYLAND_DISPLAY
  and vim.fn.executable(host_opener) == 1
then
  local function open_on_host(path)
    if path == "" then
      return
    end
    if not path:match("%w+:") then
      path = vim.fs.normalize(path)
    end
    vim.system({ host_opener, path }, { text = true, detach = true }, function(result)
      vim.schedule(function()
        local message = vim.trim((result.stdout or "") .. (result.stderr or ""))
        if result.code ~= 0 then
          vim.notify(message ~= "" and message or "Host browser opener failed", vim.log.levels.ERROR)
        elseif message ~= "" then
          vim.notify(message, vim.log.levels.INFO)
        end
      end)
    end)
  end
  vim.keymap.set("n", "gx", function()
    for _, url in ipairs(vim.ui._get_urls()) do
      open_on_host(url)
    end
  end, { desc = "Open in host browser" })
  vim.keymap.set("x", "gx", function()
    local lines = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { type = vim.fn.mode() })
    open_on_host(table.concat(vim.iter(lines):map(vim.trim):totable()))
  end, { desc = "Open in host browser" })
end

-- When we paste over a selection, don't replace the paste buffer
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Remap Ctrl-d and Ctrl-u to scroll and then center the screen.
-- This creates a more fluid scrolling experience.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down half page and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up half page and center" })

-- Move selections up and down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- move up/down with arrow keys
vim.keymap.set("n", "<Down>", "<Down>zz")
vim.keymap.set("n", "<Up>", "<Up>zz")

-- Search next/previous with the match centred. LazyVim's own n/N make n always
-- search forward and N backward, even after a `?` search; keep that and add zz.
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zzzv'", { expr = true, desc = "Next search result" })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zzzv'", { expr = true, desc = "Prev search result" })
