# LocalNest.nvim 🦉

LocalNest.nvim is a powerful, local-first AI coding assistant for Neovim. It brings state-of-the-art Large Language Model capabilities directly to your editor by connecting to your own local AI infrastructure.

This plugin is the IDE/Coding Assistant component of the [LocalNest](https://github.com/LocalNest) ecosystem.

## Features

- **Fill-In-The-Middle (FIM)**: Real-time, ghost-text code completions that understand the context before and after your cursor.
- **Multi-line Suggestions**: High-quality completions for entire functions and complex blocks.
- **Interactive Chat**: A sleek, streaming floating chat window for deep technical discussions.
- **Slash Commands**: Instant AI actions for selected code:
  - `/explain`: Get a detailed breakdown of complex logic.
  - `/fix`: Identify and resolve bugs and edge cases.
  - `/refactor`: Improve readability and performance.
  - `/test`: Automatically generate comprehensive unit tests.
- **Context-Aware**: Intelligently gathers buffer content and project context for more accurate results.
- **Tool Integration**: Seamlessly connects with `n8n` for advanced capabilities.
- **Optimized for Qwen 2.5**: Pre-tuned for the Qwen 2.5 Coder series (7B recommended).

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    'LocalNest/LocalNest.nvim',
    config = function()
        require('localnest').setup({
            llama_server = {
                host = "localhost", -- Or your local AI box
                port = 8888,
            }
        })
    end
}
```

## Keybindings

LocalNest uses `which-key` for easy discovery.

### Fill-In-The-Middle (Insert Mode)
| Shortcut | Action |
| --- | --- |
| `Auto` | Suggestions appear after a short pause |
| `<C-x>` | Manually trigger completion |
| `<C-z>` | **Accept** suggestion |
| `<C-d>` | **Dismiss** suggestion |

### AI Actions (`<leader>a`)
| Shortcut | Action |
| --- | --- |
| `<leader>ae` | Explain code |
| `<leader>af` | Fix code |
| `<leader>ar` | Refactor code |
| `<leader>at` | Generate tests |

### AI Chat (`<C-o>`)
| Shortcut | Action |
| --- | --- |
| `<C-o>c` | Open Chat |
| `<C-o>x` | Ask about Selection |
| `<C-o>f` | Analyze Full File |
| `<C-o>t` | Ask via `@this` block |

## Configuration

You can tune the AI's behavior in your `setup` function:

```lua
require('localnest').setup({
    fim = {
        enabled = true,
        auto_trigger = true,
        max_tokens = 128,
        temperature = 0.0, -- Deterministic completions
        top_p = 0.9,
    },
    chat = {
        max_tokens = 512,
        temperature = 0.7,
    }
})
```

## 🛠️ Integrated Development Environment

LocalNest is more than just an AI plugin; it's a fully-equipped IDE configured for high-performance engineering.

### Language Support (LSP)
Full IDE capabilities for:
- **Rust** (via `rust-tools.nvim`)
- **Go** (via `go.nvim`)
- **Python**, **TypeScript/JS**, **Lua**, **Bash**, **YAML**, **JSON**, **Docker*e*
- **Cap'n Proto** (dedicated support)

### Core Stack
- **Modern UI**: `tokyonight` theme with `lualine` status and `dashboard-nvim` splash screen.
- **Search & Navigation**: `telescope.nvim` with `fzf-native` for lightning-fast file and symbol searches.
- **Git Integration**: `vim-fugitive` for management and `gitsigns.nvim` for inline diffs.
- **Productivity**: 
  - `which-key.nvim`: Interactive command discovery.
  - `toggleterm.nvim`: Integrated terminal management.
  - `auto-session`: Persistent workspace sessions.
  - `nvim-surround` & `Comment.nvim`: Advanced text manipulation.

### Quality of Life Tweaks
- **Native Navigation**: Seamless window jumping with `<C-h/j/k/l>`.
- **System Clipboard**: Unified copy/paste with `Ctrl-c` and `Ctrl-v`.
- **Smooth Interaction**: Hardware-accelerated scrolling with `neoscroll.nvim`.

## Requirements

- Neovim 0.10+
- [llama-server](https://github.com/ggerganov/llama.cpp) (running with `/infill` and `/completion` endpoints)
- `curl` installed on your system

## 🦉 About LocalNest

LocalNest.nvim is built with privacy and performance in mind. No code leaves your local environment, keeping your proprietary logic safe while giving you the speed and power of modern LLMs.

---
Part of the [LocalNest](https://github.com/LocalNest) project.
