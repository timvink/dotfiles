-- Disable markdown linting. LazyVim's lang.markdown extra registers
-- markdownlint-cli2 in nvim-lint's linters_by_ft.markdown; its MD0xx rules
-- are more noise than help. A function override is required because LazyVim
-- deep-merges linters_by_ft, so an empty list in table form wouldn't clear
-- the inherited entry. Formatting (conform) is left untouched.
return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts.linters_by_ft = opts.linters_by_ft or {}
    opts.linters_by_ft.markdown = {}
  end,
}
