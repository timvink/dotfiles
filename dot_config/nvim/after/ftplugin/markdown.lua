-- Soft-wrap markdown so long lines stay on screen (like VSCode's word wrap).
--
-- LazyVim already enables `wrap` for markdown via its `lazyvim_wrap_spell`
-- autocmd, but that autocmd is only registered on the `VeryLazy` event. When
-- nvim is started without a file argument (the usual dashboard launch), any
-- markdown buffer whose filetype fires before `VeryLazy` -- most notably
-- session-restored buffers -- never gets `wrap` set and its long lines run off
-- the right edge.
--
-- An ftplugin runs from Neovim's built-in `filetypeplugin` mechanism on *every*
-- markdown buffer, independent of plugin load order, so this is reliable where
-- an autocmd in config/autocmds.lua (which loads on `VeryLazy` too) would share
-- the same blind spot.
vim.opt_local.wrap = true -- soft-wrap long lines instead of running off-screen
vim.opt_local.linebreak = true -- break at word boundaries, not mid-word
