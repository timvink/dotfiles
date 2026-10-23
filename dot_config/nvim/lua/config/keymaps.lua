-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Use space as leader key
vim.g.mapleader = " "

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

-- Remap Y to yank from the cursor to the end of the line.
-- This makes Y consistent with C and D.
vim.keymap.set("n", "Y", "y$", { desc = "Yank to end of line" })

-- '<leader>qq' to write and quit
vim.keymap.set("n", "<leader>qq", ":wq<CR>", { desc = "Write and quit" })

-- Move selections up and down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- move up/down with arrow keys
vim.keymap.set("n", "<Down>", "<Down>zz")
vim.keymap.set("n", "<Up>", "<Up>zz")

-- Keep cursor in the middle when searching next/previous
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- ':Download [path]' — copy a file to the Mac's ~/Downloads when working on the
-- devbox/homelab over SSH. No arg = the current buffer's file. Runs the
-- ~/.local/bin/downloadfile script, which writes into the reverse ~/mac-downloads
-- sshfs mount (see dot_local/lib/remote-session.sh "Reverse ~/Downloads mounts").
vim.api.nvim_create_user_command("Download", function(opts)
  local path = opts.args ~= "" and vim.fn.expand(opts.args) or vim.fn.expand("%:p")
  if path == "" then
    vim.notify("Download: no file (open a buffer or pass a path)", vim.log.levels.ERROR)
    return
  end
  vim.system({ "downloadfile", path }, { text = true }, function(res)
    vim.schedule(function()
      local msg = vim.trim((res.stdout or "") .. (res.stderr or ""))
      vim.notify(msg ~= "" and msg or "downloadfile done",
        res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end)
end, { nargs = "?", complete = "file", desc = "Copy file to Mac ~/Downloads (devbox reverse mount)" })
