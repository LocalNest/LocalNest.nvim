-- Load core configurations first
require('core.options')
require('core.keymaps')


-- TEMP: mute Neovim deprecation spam from old plugins (rust-tools, null-ls, etc.)
--vim.deprecate = function() end

-- Initialize plugin manager and plugins
require('core.plugins')

-- Load plugin configurations AFTER packer
vim.cmd [[packadd packer.nvim]]
vim.schedule(function()
  require('nvim-web-devicons').setup()
  require('plugins.dashboard')
  require('plugins.diagnostics')
  require('plugins.cmp')
  require('plugins.lsp')
  require('plugins.telescope')
  require('plugins.treesitter')
  -- Theme
  vim.cmd [[colorscheme tokyonight]]
  vim.cmd [[highlight Normal ctermfg=white ctermbg=black]]
end)

vim.opt.clipboard = "unnamedplus"
