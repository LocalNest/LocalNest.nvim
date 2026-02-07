require('nvim-treesitter').setup {
    modules = {},
    sync_install = false,
    auto_install = false,
    ignore_install = {},
    ensure_installed = {'lua', 'python', 'go', 'rust', 'capnp'}, -- Add languages
    highlight = {enable = true},
    indent = {enable = true},
  }
