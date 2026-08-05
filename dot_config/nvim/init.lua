-- Clear swap files orphaned by a crashed nvim. Registered before lazy.nvim
-- because SwapExists fires while the startup file is opened, which is earlier
-- than the VeryLazy event that would load lua/config/autocmds.lua.
require("config.stale-swap")

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")