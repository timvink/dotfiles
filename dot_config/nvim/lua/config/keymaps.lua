-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Use space as leader key
vim.g.mapleader = " "

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
-- sshfs mount (see dot_bash_aliases.tmpl "Reverse ~/Downloads mounts").
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
