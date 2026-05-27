-- Paste images from the system clipboard into markdown.
-- Saves the PNG next to the current file (./assets/) and inserts the
-- markdown link. Backend tool per OS: pngpaste (macOS), xclip (X11),
-- wl-paste (Wayland). Install those via the chezmoi package scripts.
return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      dir_path = "assets",
      relative_to_current_file = true,
      prompt_for_file_name = true,
      show_dir_path_in_prompt = true,
    },
  },
  keys = {
    -- Ctrl+V in insert mode pastes a clipboard image as a markdown link.
    -- Trade-off: replaces Vim's "insert literal char" on <C-v>; use <C-q>
    -- for that instead (e.g. <C-q><Tab> for a real tab).
    { "<C-v>", "<cmd>PasteImage<cr>", mode = "i", desc = "Paste image from clipboard" },
  },
}
