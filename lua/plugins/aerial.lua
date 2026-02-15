require("aerial").setup({
  -- optionally use on_attach to set keymaps when aerial has attached to a buffer
  on_attach = function(bufnr)
    -- Jump forwards/backwards with '{' and '}'
    vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
  end,
  layout = {
    max_width = { 40, 0.2 },
    width = nil,
    min_width = 20,
  },
  icons = {
    Class          = " ",
    Constructor    = " ",
    Enum           = " ",
    Function       = " ",
    Interface      = " ",
    Module         = " ",
    Method         = " ",
    Struct         = " ",
  },
})
