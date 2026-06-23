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

-- Over SSH, mirror yanks to the *host* machine's clipboard via OSC 52, so text
-- yanked in nvim (on the homelab, a devbox, …) can be pasted into another app on
-- the Mac. tmux forwards the escape onward (`set-clipboard on`) and Ghostty drops
-- it on the macOS clipboard. Two things have to happen for a plain `y` to feed
-- that chain:
--
--  1. The clipboard *provider* must be OSC 52 — pinned explicitly here rather
--     than letting nvim probe for xclip/wl-copy, which over SSH would target the
--     box's unreachable headless X clipboard.
--  2. `clipboard` must include `unnamedplus` so `y` writes the `+` register.
--     LazyVim sets `clipboard = ""` whenever $SSH_CONNECTION is set, and (the
--     subtle part) it *defers* that: config/init.lua captures the value, blanks
--     it for startup, and re-applies `""` on the VeryLazy event — which fires
--     after this file. So assigning `clipboard` here is silently clobbered. We
--     re-assert it inside a VeryLazy autocmd, vim.schedule-d so it lands after
--     LazyVim's own VeryLazy handler regardless of autocmd registration order.
--
-- Paste is left reading the unnamed register: an OSC 52 *read* round-trips a
-- terminal query that tmux/Ghostty often won't answer, which would hang `p`. So
-- `+`/`*` paste returns what nvim last yanked, and pasting host-clipboard text
-- *into* nvim stays a normal terminal paste (⌘V).
if vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  local from_reg = function()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = from_reg, ["*"] = from_reg },
  }
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      vim.schedule(function()
        vim.opt.clipboard = "unnamedplus"
      end)
    end,
  })
end
