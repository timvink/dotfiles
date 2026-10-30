return {
  "folke/snacks.nvim",
  opts = {
    -- Render image files (and inline markdown images) in the buffer via the
    -- Kitty graphics protocol instead of showing raw bytes. Works because the
    -- outer terminal is Ghostty (speaks the protocol) and tmux is told to pass
    -- the escapes through (`allow-passthrough on` in dot_tmux.conf). Needs the
    -- `magick` CLI (ImageMagick) on PATH — see the package scripts. Just open a
    -- .png/.jpg/.svg/.pdf/… and it displays; :checkhealth snacks reports status.
    image = { enabled = true },
    -- Fall back to indent-based scope detection. snacks.scope's async
    -- treesitter parse trips an `attempt to call method 'range' (a nil
    -- value)` crash on BufReadPost under nvim 0.12.2 — the failing
    -- code path is unchanged on snacks' main, so avoid it.
    scope = { treesitter = { enabled = false } },
    picker = {
      sources = {
        -- Where the projects picker (dashboard `p`, `<leader>fp`) scans for repos.
        projects = {
          dev = { "~/workspace" },
        },
      },
    },
  },
}
