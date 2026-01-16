local ensure_packer = function()
    local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
    if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
        vim.fn.system({
            'git', 'clone', '--depth', '1',
            'https://github.com/wbthomason/packer.nvim',
            install_path
        })
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
    -- Package manager
    use 'wbthomason/packer.nvim'

    -- Language stuff
    use("neovim/nvim-lspconfig")
    use("hrsh7th/nvim-cmp") -- Autocompletion framework
    use({
        -- cmp LSP completion
        "hrsh7th/cmp-nvim-lsp",
        -- cmp Snippet completion
        "hrsh7th/cmp-vsnip",
        -- cmp Path completion
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-buffer",
        after = { "hrsh7th/nvim-cmp" },
        requires = { "hrsh7th/nvim-cmp" },
    })

    use("nvim-lua/popup.nvim")
    -- Snippet engine
    use('hrsh7th/vim-vsnip')
    -- Adds extra functionality over rust analyzer
    use("simrat39/rust-tools.nvim")

    -- Go development
    use {
        'ray-x/go.nvim',
        requires = {
            'ray-x/guihua.lua',
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require('go').setup()
        end,
        event = { "CmdlineEnter" },
        ft = { "go", 'gomod' },
        build = ':lua require("go.install").update_all_sync()'
    }

    -- Better diagnostics
    use {
        "folke/trouble.nvim",
        requires = "nvim-tree/nvim-web-devicons",
    }

    -- File explorer
    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons',
        },
    }

    -- Core Utilities
    use 'nvim-lua/plenary.nvim'
    use 'nvim-tree/nvim-web-devicons'
    use 'windwp/nvim-autopairs'

    -- Treesitter
    use 'nvim-treesitter/nvim-treesitter'
    use {
        'nvim-telescope/telescope-fzf-native.nvim',
        run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release',
    }
    -- Telescope
    use 'nvim-telescope/telescope.nvim'

    -- Github
    use 'j-hui/fidget.nvim'
    use 'numToStr/Comment.nvim'
    use 'tpope/vim-fugitive'
    use 'lewis6991/gitsigns.nvim'

    -- Themes
    use 'stevearc/dressing.nvim'
    use {
        'glepnir/dashboard-nvim',
        requires = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('plugins.dashboard')
        end
    }
    use 'lvimuser/lsp-inlayhints.nvim'
    use 'folke/tokyonight.nvim'

    -- Additional productivity plugins
    use {
        'folke/which-key.nvim',
        config = function()
            require('which-key').setup()
        end
    }

    -- Better UI
    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    }

    -- Indent guides
    use 'lukas-reineke/indent-blankline.nvim'

    -- Better terminal
    use { "akinsho/toggleterm.nvim", tag = '*' }

    -- Session management
    use {
        'rmagatti/auto-session',
        config = function()
            require("auto-session").setup {
                log_level = "error",
                auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
            }
        end
    }

    -- Formatting
    use 'jose-elias-alvarez/null-ls.nvim'

    -- Better surround
    use 'kylechui/nvim-surround'

    -- Smooth scrolling
    use 'karb94/neoscroll.nvim'




    use {
        vim.fn.stdpath('config') .. '/lua/localnest',
        config = function()
            require('localnest').setup({})
        end,
    }


    if packer_bootstrap then
        require('packer').sync()
    end
end)
