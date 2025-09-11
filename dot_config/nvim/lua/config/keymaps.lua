-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

 
-- Use space as leader key
vim.g.mapleader = " "

-- Pasting with 'p' replaces the copy buffer, now '<leader>p' does not
vim.keymap.set('x', '<leader>p', '"_dP')

-- Remap Ctrl-d and Ctrl-u to scroll and then center the screen.
-- This creates a more fluid scrolling experience.
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down half page and center' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up half page and center' })

-- Remap Y to yank from the cursor to the end of the line.
-- This makes Y consistent with C and D.
vim.keymap.set('n', 'Y', 'y$', { desc = 'Yank to end of line' })

-- '<leader>qq' to write and quit
vim.keymap.set('n', '<leader>qq', ':wq<CR>', { desc = 'Write and quit' })
-- Add any additional keymaps here
