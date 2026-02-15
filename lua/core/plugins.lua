local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Language stuff
    "neovim/nvim-lspconfig",
    "hrsh7th/nvim-cmp", -- Autocompletion framework
    {
        "hrsh7th/cmp-nvim-lsp",
        dependencies = { "hrsh7th/nvim-cmp" },
    },
    {
        "hrsh7th/cmp-vsnip",
        dependencies = { "hrsh7th/nvim-cmp" },
    },
    {
        "hrsh7th/cmp-path",
        dependencies = { "hrsh7th/nvim-cmp" },
    },
    {
        "hrsh7th/cmp-buffer",
        dependencies = { "hrsh7th/nvim-cmp" },
    },

    "nvim-lua/popup.nvim",
    -- Snippet engine
    'hrsh7th/vim-vsnip',
    -- Adds extra functionality over rust analyzer
    "simrat39/rust-tools.nvim",

    -- Go development
    {
        'ray-x/go.nvim',
        dependencies = {
            'ray-x/guihua.lua',
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require('go').setup()
        end,
        event = { "CmdlineEnter" },
        ft = { "go", 'gomod' },
        build = ':lua require("go.install").update_all_sync()'
    },

    -- Better diagnostics
    {
        "folke/trouble.nvim",
        dependencies = "nvim-tree/nvim-web-devicons",
    },

    -- File explorer
    {
        'nvim-tree/nvim-tree.lua',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
    },

    -- Core Utilities
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'windwp/nvim-autopairs',

    -- Treesitter
    'nvim-treesitter/nvim-treesitter',
    {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
    },
    -- Telescope
    'nvim-telescope/telescope.nvim',

    -- Github
    'j-hui/fidget.nvim',
    'numToStr/Comment.nvim',
    'tpope/vim-fugitive',
    'lewis6991/gitsigns.nvim',

    -- Themes
    'stevearc/dressing.nvim',
    {
        'glepnir/dashboard-nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('plugins.dashboard')
        end
    },
    'lvimuser/lsp-inlayhints.nvim',
    'folke/tokyonight.nvim',

    -- Additional productivity plugins
    {
        'folke/which-key.nvim',
        config = function()
            require('which-key').setup()
        end
    },

    -- Better UI
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },

    -- Indent guides
    'lukas-reineke/indent-blankline.nvim',

    -- Better terminal
    { "akinsho/toggleterm.nvim", version = '*' },

    -- Session management
    {
        'rmagatti/auto-session',
        config = function()
            require("auto-session").setup {
                log_level = "error",
                auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
            }
        end
    },

    -- Formatting
    'jose-elias-alvarez/null-ls.nvim',

    -- Better surround
    'kylechui/nvim-surround',

    -- Smooth scrolling
    'karb94/neoscroll.nvim',

    -- Mason for tool management
    {
        "williamboman/mason.nvim",
        dependencies = { "williamboman/mason-lspconfig.nvim" },
    },

    -- DAP (Debugger)
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "theHamsta/nvim-dap-virtual-text",
            "nvim-neotest/nvim-nio",
        },
    },

    -- Aerial (Code Outline)
    {
        "stevearc/aerial.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons", "nvim-treesitter/nvim-treesitter" },
    },

    -- Bufferline (Tabs)
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons'
    },

    -- Neotest
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antlr/antlr4",
            "nvim-treesitter/nvim-treesitter",
            -- Adapters
            "nvim-neotest/neotest-go",
            "rouge8/neotest-rust",
            "nvim-neotest/neotest-python",
        }
    },

    {
        dir = vim.fn.stdpath('config') .. '/lua/localnest',
        config = function()
            require('localnest').setup({})
        end,
    },
})
