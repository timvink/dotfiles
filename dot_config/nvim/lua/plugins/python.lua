-- Make pyright use a project's local `.venv` automatically.
--
-- Pyright -- unlike VSCode's Python extension -- does not auto-detect a `.venv`
-- in the project root. With no interpreter configured it runs against only its
-- bundled typeshed and resolves no third-party imports, producing errors like
-- `Import "starlette.types" could not be resolved` even though the package is
-- installed in `.venv`. LazyVim's python extra ships venv-selector.nvim for
-- this, but that requires a manual `:VenvSelect` (<leader>cv) per project.
--
-- This hook points pyright at `<root>/.venv/bin/python` whenever that file
-- exists, so any uv/virtualenv project resolves imports with zero manual steps.
-- The guard means non-Python projects and projects without a `.venv` are left
-- untouched, and venv-selector can still override the interpreter at runtime.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pyright = {
        before_init = function(_, config)
          local root = config.root_dir
          if not root then
            return
          end
          local venv_python = root .. "/.venv/bin/python"
          if vim.uv.fs_stat(venv_python) then
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = venv_python
          end
        end,
      },
    },
  },
}
