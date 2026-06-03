-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use smart indentation
vim.opt.smartindent = true

-- Relative line numbers, for quick jumps with j/k
vim.opt.relativenumber = true

-- Spell-check Dutch as well as English. LazyVim already enables `spell` for
-- prose filetypes (markdown, text, gitcommit); this just adds the nl dictionary
-- so Dutch words stop being flagged. First time nvim sees `nl` it offers to
-- download the dictionary (~/.local/share/nvim/site/spell/nl.utf-8.spl).
vim.opt.spelllang = { "en", "nl" }
