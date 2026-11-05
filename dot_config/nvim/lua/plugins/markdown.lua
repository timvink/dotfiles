-- Keep long Markdown lines readable in rendered view as well as while editing.
-- Wrapping is window-wide, so wide tables may wrap along with prose.
-- Scope this to listed buffers so LSP hover windows keep their wrapping.
local markdown_view = {
  win_options = {
    wrap = { default = true, rendered = true },
  },
}

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      overrides = {
        buflisted = {
          [true] = markdown_view,
        },
      },
    },
  },
  -- Disable markdown linting. LazyVim's lang.markdown extra registers
  -- markdownlint-cli2 in nvim-lint's linters_by_ft.markdown; its MD0xx rules
  -- are more noise than help. A function override is required because LazyVim
  -- deep-merges linters_by_ft, so an empty list wouldn't clear the inherited
  -- entry. Formatting (conform) is left untouched.
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
    end,
  },
}
