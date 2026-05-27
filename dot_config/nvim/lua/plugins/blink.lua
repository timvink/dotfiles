-- Show dotfiles in blink.cmp's path completion so paths like
-- `../.claude/CLAUDE.md` can be completed.
return {
  "saghen/blink.cmp",
  opts = {
    sources = {
      -- In prose, the `buffer` source scrapes words from open buffers and
      -- pollutes the popup. Drop it for markdown; keep LSP (fenced code
      -- blocks), snippets, and path (link targets).
      per_filetype = {
        markdown = { "lsp", "path", "snippets" },
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
