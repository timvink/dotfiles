-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Use space as leader key
vim.g.mapleader = " "

-- Pasting with 'p' replaces the copy buffer, now '<leader>p' does not
xnoremap("<leader>p", "\"_dP")

-- Remap Ctrl-d and Ctrl-u to scroll and then center the screen.
-- This creates a more fluid scrolling experience.
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down half page and center' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up half page and center' })

-- Remap Y to yank from the cursor to the end of the line.
-- This makes Y consistent with C and D.
vim.keymap.set('n', 'Y', 'y$', { desc = 'Yank to end of line' })

-- Use smart indentation
vim.opt.smartindent = true

-- Relative line numbers, for quick jumps with j/k
vim.opt.relativenumber = true

-- More settings to look at:
-- https://github.com/ThePrimeagen/init.lua/blob/78fe7448e98707d1e787ed5e8ef03367132fc103/lua/theprimeagen/set.lua#L11