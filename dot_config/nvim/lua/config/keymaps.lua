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
