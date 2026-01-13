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


    --opencode
    use({
        "NickvanDyke/opencode.nvim",
        requires = {
            {
                "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} }
            },
        },
        config = function()
            vim.o.autoread = true
        end,
    })

    use {
        'milanglacier/minuet-ai.nvim',
        config = function()
            require('minuet').setup {
                provider = 'openai_fim_compatible',
                n_completions = 1,
                context_window = 1024,
                request_timeout = 5,
                throttle = 400,
                debounce = 150,

                virtualtext = {
                    auto_trigger_ft = { 'lua', 'rust', 'go', 'typescript', 'javascript', 'python' },
                    keymap = {
                        accept         = '<C-b>',
                        accept_line    = '<C-n>',
                        accept_n_lines = '<C-m>',
                        next           = '<C-g>',
                        prev           = '<C-p>',
                        dismiss        = '<C-q>',
                    },
                    show_on_completion_menu = true,
                },

                provider_options = {
                    openai_fim_compatible = {
                        api_key   = 'TERM',
                        name      = 'Ollama',
                        end_point = 'http://localnest:8888/v1/completions',
                        model     = 'qwen2.5-coder:7b',
                        stream    = true,
                        optional  = {
                            max_tokens  = 12,
                            top_p       = 0.9,
                            temperature = 0.0,
                        },
                    },
                },
            }
        end,
    }

    if packer_bootstrap then
        require('packer').sync()
    end
end)
