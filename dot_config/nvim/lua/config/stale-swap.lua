-- Drop swap files orphaned by a crashed / SIGKILLed / rebooted nvim.
--
-- A clean exit — including the SIGHUP that `tmux kill-session` sends — makes nvim
-- delete its own swap. Only an *ungraceful* death (crash, kill -9, reboot, OOM)
-- leaves one behind, and then every later open of that file stops on the E325
-- "ATTENTION / found a swap file" wall, which has to be dismissed by hand.
--
-- We only auto-delete when the swap provably holds nothing worth recovering:
--
--   * same host       — a swap synced from another machine is never ours to judge
--   * owner is dead   — a live pid means another nvim genuinely has the file open,
--                       so the prompt must still appear (that is the case E325 is
--                       actually for)
--   * no unsaved work — either the swap is clean (`dirty == 0`), or the file on
--                       disk has been written *since* the swap was last touched,
--                       which is nvim's own "NEWER than swap file!" case and means
--                       the swap's contents are superseded
--
-- Anything else (a dirty swap over a file that has *not* moved on) falls through
-- to the normal prompt, so real recovery data is never silently discarded.
--
-- Loaded from init.lua rather than lua/config/autocmds.lua on purpose: LazyVim
-- defers autocmds.lua to the VeryLazy event, which fires *after* the startup file
-- is opened — too late, since that open is exactly what raises SwapExists.

local function pid_alive(pid)
  if not pid or pid <= 0 then
    return false
  end
  -- signal 0 probes for existence without delivering anything
  local ok, res = pcall(vim.uv.kill, pid, 0)
  return ok and res == 0
end

vim.api.nvim_create_autocmd("SwapExists", {
  desc = "Silently drop swap files left behind by a crashed nvim",
  callback = function(args)
    local info = vim.fn.swapinfo(vim.v.swapname)
    if type(info) ~= "table" or info.error then
      return -- unreadable swap: leave the prompt alone
    end
    if info.host ~= vim.fn.hostname() then
      return
    end
    if pid_alive(tonumber(info.pid)) then
      return
    end

    local superseded = tonumber(info.dirty) == 0
    if not superseded then
      local stat = vim.uv.fs_stat(args.file)
      local swap_mtime = tonumber(info.mtime)
      if stat and swap_mtime then
        superseded = stat.mtime.sec > swap_mtime
      end
    end
    if not superseded then
      return
    end

    vim.v.swapchoice = "d"
    vim.schedule(function()
      vim.notify("Deleted stale swap file from a crashed nvim", vim.log.levels.INFO)
    end)
  end,
})
