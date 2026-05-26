-- Show dotfiles in blink.cmp's path completion so paths like
-- `../.claude/CLAUDE.md` can be completed.
return {
  "saghen/blink.cmp",
  opts = {
    sources = {
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
