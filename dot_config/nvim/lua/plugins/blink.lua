-- Show dotfiles in blink.cmp's path completion so paths like
-- `../.claude/CLAUDE.md` can be completed.
return {
  "saghen/blink.cmp",
  opts = {
    -- Don't pop the menu up while typing; it kept interrupting. Open it on
    -- demand with <C-Space> (blink's default "show" key). Omarchy keeps
    -- LazyVim's auto-show, so this is a deliberate departure from it.
    completion = {
      menu = { auto_show = false },
    },
    sources = {
      -- In prose, the `buffer` source scrapes words from open buffers and
      -- pollutes the popup. Drop it for markdown; also drop `snippets` — the
      -- table~ / NxMtable~ shorthands kept popping up mid-sentence and broke
      -- the flow of writing prose. Keep LSP (fenced code blocks) and path
      -- (link targets), which only trigger on code/`/`, not on normal words.
      per_filetype = {
        markdown = { "lsp", "path" },
      },
      providers = {
        path = {
          opts = {
            show_hidden_files_by_default = true,
          },
        },
      },
    },
  },
}
