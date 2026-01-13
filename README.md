# 🚀 Kodr's Neovim Configuration (2026)

> Modern Neovim setup optimized for Rust, Go, TypeScript, Python, Solidity, and Cap’n Proto — with local AI completion via Ollama

## ✨ Features

- 🤖 **AI completion with Minuet + Ollama**
  - Fill‑in‑the‑middle (FIM) inline suggestions using `qwen2.5-coder` via Minuet.[1][2]
  - Integrated as a high‑priority source in `nvim-cmp` with tuned timeouts for LLM latency.[3]
- 🎯 Unified LSP setup
  - Single `on_attach`/`capabilities` pipeline for Go, Rust, Python, TS/JS, Lua, Bash, Docker, YAML, JSON, Solidity, and Cap’n Proto.  
  - Root‑dir detection via common markers and Rust format‑on‑save.  
- 🦀 Rust‑focused workflow
  - `rust-analyzer` managed by the unified LSP, plus Rust‑specific formatting and code actions.  
- 🌳 Modern editing experience
  - Treesitter for Rust/Go/TS/JS/Python/Lua/Solidity/Cap’n Proto and more.[4]
  - Telescope, Git integration, and a minimal, fast UI.

Copilot is no longer required: all AI completion is local via Ollama + Minuet.

***

## 🎯 Quick Start

1. Clone this config:
   ```bash
   git clone https://github.com/BradMyrick/nvim-config.git ~/.config/nvim
   ```

2. Install Neovim and core tools:
   ```bash
   # Neovim 0.10.0 or higher required
   sudo add-apt-repository ppa:neovim-ppa/unstable
   sudo apt update
   sudo apt install neovim

   # Extra tools for plugins
   sudo apt install ripgrep fd-find cmake gcc make
   ```

3. Rust + friends:
   ```bash
   rustup component add rust-analyzer
   ```

4. Treesitter and LSP dependencies are auto‑managed:
   - Treesitter ensures languages like Rust, Go, TS, Lua, Python, and `capnp` are installed.[4]
   - Mason (or equivalent) installs language servers (gopls, pyright, lua_ls, tsserver, bashls, dockerls, yamlls, jsonls, rust-analyzer, etc.) via a unified config.

5. AI backend (optional but recommended):
   - Install [Ollama](https://ollama.com) and pull a coder model:
     ```bash
     ollama pull qwen2.5-coder:7b
     ```
   - Ensure Ollama’s OpenAI‑compatible API is available on `http://localhost:11434/v1/completions` (default with recent Ollama builds).[5]

6. Open Neovim and install plugins:
   ```vim
   :PackerSync  " or :Lazy sync if you’ve switched managers
   ```

***

## ⌨️ Key Mappings

Only the interesting ones; everything else is “boring Vim defaults”.

### 📁 Files & Buffers

| Mapping | Mode | Description            |
|--------|------|------------------------|
| `pv`   | `n`  | Open file explorer     |
| `w`    | `n`  | Save buffer            |
| `q`    | `n`  | Close buffer           |
| `n`    | `n`  | New file               |

### 🔍 LSP Navigation

| Mapping | Mode | Description        |
|--------|------|--------------------|
| `gd`   | `n`  | Go to definition   |
| `gr`   | `n`  | List references    |
| `K`    | `n`  | Hover docs         |
| `rn`   | `n`  | Rename symbol      |
| `f`    | `n`  | Format buffer      |

### 🌳 Git

| Mapping | Mode | Description  |
|--------|------|--------------|
| `gs`   | `n`  | Git status   |
| `gc`   | `n`  | Git commit   |
| `gp`   | `n`  | Git pull     |
| `gu`   | `n`  | Git push     |

### 🪟 Windows & Terminal

| Mapping | Mode | Description           |
|--------|------|-----------------------|
| `<C-h/j/k/l>` | `n` | Navigate windows |
| `t`    | `n`  | Open terminal split   |
| `<Esc>`| `t`  | Exit terminal mode    |

### 🦀 Rust‑specific

| Mapping | Mode | Description                    |
|--------|------|--------------------------------|
| `a`    | `n`  | Rust code actions (RustLsp)    |
| `K`    | `n`  | Rust hover actions             |
| `rr`   | `n`  | Run current Rust file          |
| `tm`   | `n`  | View crate graph               |

### 🤖 Minuet AI (virtual text)

Minuet shows inline ghost text; these are the controls:[2][1]

| Mapping | Description                    |
|--------|--------------------------------|
| `<C-b>`| Accept full suggestion         |
| `<C-n>`| Accept one line                |
| `<C-m>`| Accept N lines (prompted)      |
| `<C-g>`| Trigger / next suggestion      |
| `<C-p>`| Previous suggestion            |
| `<C-q>`| Dismiss current suggestion     |

***

## 🔧 LSP & Completion Configuration

### Unified LSP setup

Key ideas:

- Single `on_attach` for all servers (keymaps, formatting, etc.).  
- Single `capabilities` object shared across servers for `nvim-cmp`.  
- Rust uses the same LSP path as other languages but is configured to format on save and use `rust-analyzer` features fully.

Example sketch:

```lua
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local on_attach = function(client, bufnr)
  -- LSP keymaps here
  -- Rust: format on save
  if client.name == 'rust_analyzer' then
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      callback = function() vim.lsp.buf.format({ async = false }) end,
    })
  end
end

local servers = {
  'gopls',
  'pyright',
  'tsserver',
  'lua_ls',
  'bashls',
  'dockerls',
  'yamlls',
  'jsonls',
  'rust_analyzer',
  'solidity_ls',    -- if present
  'capnp_ls',       -- Cap’n Proto server
}

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    root_dir = lspconfig.util.root_pattern('.git', 'Cargo.toml', 'go.mod', 'package.json'),
  })
end
```

Cap’n Proto and Solidity servers are wired into the same pipeline, so they get completion, diagnostics, and formatting where supported.

### Treesitter

Treesitter is configured to ensure Rust, Go, TS/JS, Lua, Python, Solidity, and `capnp` are always installed, with incremental selection and better indentation enabled.[4]

***

## 🤖 AI Completion: Minuet + Ollama

### Minuet core setup

Minuet provides the AI source via both in‑process LSP and as a `nvim-cmp` source for completion.[1][3]

```lua
require('minuet').setup {
  provider = 'openai_fim_compatible',
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
      api_key   = 'TERM',  -- tells Minuet to read from $OPENAI_API_KEY, but here it’s ignored for Ollama
      name      = 'Ollama',
      end_point = 'http://localhost:11434/v1/completions',
      model     = 'qwen2.5-coder:7b',
      stream    = true,
      optional  = {
        max_tokens  = 12,  -- tuned for short, line/loop-level FIM
        top_p       = 0.9,
        temperature = 0.0,
      },
      -- no custom template: rely on Minuet’s FIM handling for Qwen
    },
  },
}
```

### `nvim-cmp` integration

Minuet is added as a high‑priority `nvim-cmp` source, with LLM‑aware performance tuning.[3][2]

```lua
local cmp = require('cmp')

cmp.setup({
  sources = cmp.config.sources({
    { name = 'minuet', priority = 1000 },
    { name = 'nvim_lsp' },
    { name = 'path' },
    { name = 'buffer' },
  }),
  performance = {
    max_view_entries = 40,
    fetching_timeout = 500,  -- give LLMs time
  },
})

-- Disable completion for capnp if desired
cmp.setup.filetype('capnp', {
  sources = {},  -- no cmp sources for capnp
})
```

Minuet can also run as an in‑process LSP; the config is set so it cooperates with other LSP servers instead of replacing them.[1][3]

***

## 🎯 Language Support (2026)

- **Rust**: `rust-analyzer` + Treesitter, format‑on‑save, rich code actions.  
- **Go**: `gopls` with LSP, Treesitter.  
- **TypeScript / JavaScript**: `tsserver` + Treesitter.  
- **Python**: `pyright` + Treesitter.  
- **Lua**: `lua_ls` for Neovim config and plugin hacking.  
- **Solidity**: Smart contract dev via Solidity LSP and Treesitter (where supported).  
- **Cap’n Proto**: LSP + Treesitter configured and kept up to date.  

AI completion is available across most of these via Minuet’s FIM integration.

***

## 🧠 Commit History Highlights

Recent changes that shaped this setup:

- **feat: enhance LSP and completion setup with AI integration**
  - Added Minuet as a high‑priority `nvim-cmp` source and a manual completion trigger.  
  - Tuned completion performance to avoid timeouts with LLM‑backed sources.  
  - Disabled completion for `capnp` filetype where it got in the way.  

- **refactor: unify LSP configuration for multiple languages**
  - Replaced the older Rust‑only tooling with a unified LSP pipeline for Go, Python, TS, Lua, Bash, Docker, YAML, JSON, Rust, and Cap’n Proto.  
  - Added shared `capabilities`/`on_attach` and root detection.  
  - Configured Rust to format on save and wired a Cap’n Proto language server.  

- **fix: update Treesitter configuration**
  - Ensured `capnp` is installed.  
  - Cleaned up Treesitter module and install settings.  

- **chore: remove outdated zshrc configuration**
  - Dropped a stray `zshrc` file that wasn’t part of the Neovim setup.

***

## 🤝 Contributing / Forking

This config is opinionated around Rust, Go, TS, Python, Solidity, and Cap’n Proto with local AI. PRs, issues, and forks are welcome — especially around:

- Better FIM models or Ollama templates.  
- Per‑language tuning for Minuet (different `max_tokens`/models per filetype).  
- Additional LSPs and formatters.

***

Made with ☕ and local silicon by Kodr.
