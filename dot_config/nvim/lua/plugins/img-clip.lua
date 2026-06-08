-- Paste images from the system clipboard into markdown.
-- Saves the PNG next to the current file (./assets/) and inserts the
-- markdown link. Backend tool per OS: pngpaste (macOS), xclip (X11),
-- wl-paste (Wayland). Install those via the chezmoi package scripts.
return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  ft = { "markdown", "markdown.mdx" },
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "markdown.mdx" },
      callback = function(event)
        vim.keymap.set("i", "<C-v>", "<cmd>PasteImage<cr>", {
          buffer = event.buf,
          desc = "Paste image from clipboard",
        })
      end,
    })
  end,
  opts = {
    default = {
      dir_path = "assets",
      relative_to_current_file = true,
      prompt_for_file_name = true,
      show_dir_path_in_prompt = true,
    },
  },
}
