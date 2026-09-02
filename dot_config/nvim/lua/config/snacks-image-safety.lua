-- snacks.nvim's image previewer hard-crashes on a corrupt/empty file:
-- `dim()` in snacks/image/util.lua asserts the PNG magic bytes and throws
-- instead of failing softly. That assert can fire well after a buffer
-- "opened" fine, since placement re-fits are debounced off a *global*
-- WinClosed autocmd — closing any window can retrigger it. Local
-- workaround until upstream guards it; drop this once it does.
local ok, util = pcall(require, "snacks.image.util")
if not ok then
  return
end

local dim = util.dim
function util.dim(file)
  local dim_ok, size = pcall(dim, file)
  if dim_ok then
    return size
  end
  return { width = 1, height = 1 }
end
