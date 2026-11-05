" Obsidian Vim mode keymaps, loaded by the Vimrc Support plugin
" (obsidian-vimrc-support, pinned in .chezmoiexternal.toml).
"
" Space is the leader, as in Neovim (dot_config/nvim/lua/config/keymaps.lua).
" Vimrc Support 0.10.2 has no `let mapleader`, so Space is unmapped from its
" default (move right) and its chords are mapped directly.
unmap <Space>

" Space-e shows the Files sidebar, like LazyVim's Neo-tree on <leader>e.
" obcommand only takes its argument through an exmap alias (CodeMirror passes
" mappings just the first word), hence the two-step form.
exmap explorer obcommand file-explorer:open
nmap <Space>e :explorer<CR>

" Space-Space: Quick Switcher (jump to a note by name), like LazyVim's
" find-files. Space-/: full-text search over all notes (also Cmd+K).
exmap switcher obcommand switcher:open
nmap <Space><Space> :switcher<CR>
exmap searchall obcommand global-search:open
nmap <Space>/ :searchall<CR>

" Yank and put through the macOS clipboard, like `clipboard=unnamedplus`.
set clipboard=unnamed
