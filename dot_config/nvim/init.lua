-- Clear swap files orphaned by a crashed nvim. Registered before lazy.nvim
-- because SwapExists fires while the startup file is opened, which is earlier
-- than the VeryLazy event that would load lua/config/autocmds.lua.
require("config.stale-swap")

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- The shell's `n` shortcut opens the project tree once LazyVim is ready.
vim.api.nvim_create_user_command("NeoTreeOnStartup", function()
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      require("neo-tree.command").execute({ dir = LazyVim.root() })
    end,
  })
end, {})

-- must run after config.lazy: needs snacks.nvim on the runtime path
require("config.snacks-image-safety")
