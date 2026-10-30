-- Neovim wraps whole buffer lines, not individual table cells. When a rendered
-- table exceeds the window width, its inline padding and borders spill onto
-- continuation lines and the columns break apart. Keep rendered Markdown
-- unwrapped (zh/zl scroll horizontally), but retain prose wrapping in raw view
-- and insert mode. This is window-wide, so rendered prose is unwrapped too.
-- Scope this to listed buffers so LSP hover windows keep their wrapping.
local markdown_view = {
  win_options = {
    wrap = { default = true, rendered = false },
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
