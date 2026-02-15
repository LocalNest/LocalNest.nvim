require("bufferline").setup({
  options = {
    mode = "buffers",
    offsets = {
      {
        filetype = "NvimTree",
        text = "File Explorer",
        text_align = "left",
        separator = true,
      },
      {
        filetype = "aerial",
        text = "Outline",
        text_align = "left",
        separator = true,
      },
    },
    show_buffer_close_icons = false,
    show_close_icon = false,
    color_icons = true,
  },
})
