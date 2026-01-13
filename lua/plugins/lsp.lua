-- lua/plugins/lsp.lua
-- Unified native LSP config (Neovim 0.11+)

---------------------------------------------------------------
-- Dependencies
---------------------------------------------------------------

local cmp_nvim_lsp = require("cmp_nvim_lsp")

---------------------------------------------------------------
-- Diagnostics
---------------------------------------------------------------

vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
    source = "if_many",
  },
  float = {
    source = true,
    border = "rounded",
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

---------------------------------------------------------------
-- Shared capabilities + on_attach
---------------------------------------------------------------

local capabilities = cmp_nvim_lsp.default_capabilities()

local on_attach = function(client, bufnr)
  -- inlay hints when supported
  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
end

---------------------------------------------------------------
-- Helpers
---------------------------------------------------------------

local function root_with(markers)
  return function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == "" then
      fname = vim.loop.cwd() or "."
    end
    local start = vim.fs.dirname(fname)
    local found = vim.fs.find(markers, { upward = true, path = start })[1]
    local root = found and vim.fs.dirname(found) or start
    on_dir(root)
  end
end

---------------------------------------------------------------
-- Rust: format on save
---------------------------------------------------------------

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rs",
  callback = function(args)
    vim.lsp.buf.format({
      bufnr = args.buf,
      async = false,
      timeout_ms = 1000,
    })
  end,
})

---------------------------------------------------------------
-- LSP servers (vim.lsp.config / vim.lsp.enable)
---------------------------------------------------------------

-- Go (gopls)
vim.lsp.config("gopls", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = root_with({ "go.work", "go.mod", ".git" }),
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        unusedparams = true,
        shadow = true,
        nilness = true,
        unusedwrite = true,
        useany = true,
      },
      staticcheck = true,
      gofumpt = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})
vim.lsp.enable("gopls")

-- Python (pyright)
vim.lsp.config("pyright", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_dir = root_with({
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  }),
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
      },
    },
  },
})
vim.lsp.enable("pyright")

-- TypeScript / JavaScript (ts_ls)
vim.lsp.config("ts_ls", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_dir = root_with({ "package.json", "tsconfig.json", "jsconfig.json", ".git" }),
  init_options = {
    hostInfo = "neovim",
  },
})
vim.lsp.enable("ts_ls")

-- Lua (lua-language-server)
vim.lsp.config("lua_ls", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = root_with({
    ".emmyrc.json",
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
  }),
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
      hint = {
        enable = true,
        semicolon = "Disable",
      },
      codeLens = {
        enable = true,
      },
    },
  },
})
vim.lsp.enable("lua_ls")

-- Bash (bashls)
vim.lsp.config("bashls", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "bash-language-server", "start" },
  filetypes = { "bash", "sh" },
  root_dir = root_with({ ".git" }),
  settings = {
    bashIde = {
      globPattern = "*@(.sh|.inc|.bash|.command)",
    },
  },
})
vim.lsp.enable("bashls")

-- Docker (dockerls)
vim.lsp.config("dockerls", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_dir = root_with({ "Dockerfile", ".git" }),
})
vim.lsp.enable("dockerls")

-- YAML (yamlls)
vim.lsp.config("yamlls", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
  root_dir = root_with({ ".git" }),
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      format = { enable = true },
    },
  },
})
vim.lsp.enable("yamlls")

-- JSON (jsonls)
vim.lsp.config("jsonls", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_dir = root_with({ ".git" }),
  init_options = {
    provideFormatter = true,
  },
})
vim.lsp.enable("jsonls")

-- Rust (rust-analyzer)
vim.lsp.config("rust_analyzer", {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_dir = root_with({ "Cargo.toml", "rust-project.json", ".git" }),
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = true,
      imports = { granularity = { group = "module" } },
      cargo = { buildScripts = { enable = true } },
      procMacro = { enable = true },
    },
  },
})
vim.lsp.enable("rust_analyzer")

---------------------------------------------------------------
-- Cap'n Proto: filetype + capnp_ls
---------------------------------------------------------------

vim.filetype.add({
  extension = { capnp = "capnp" },
})

vim.lsp.config("capnp_ls", {
  cmd = { "/home/kodr/capnp-ls/build/capnp-ls" },
  filetypes = { "capnp" },
  root_markers = { ".git", "capnp.toml", "capnp.json" },
  on_attach = on_attach,
  capabilities = capabilities,
  init_options = {
    capnp = {
      compilerPath = "/usr/local/bin/capnp",
      importPaths = { "." },
    },
  },
})
vim.lsp.enable("capnp_ls")
