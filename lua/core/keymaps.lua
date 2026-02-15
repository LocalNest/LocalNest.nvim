local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Set leader key
vim.g.mapleader = ' '

-- Basic mappings
map('n', '<leader>pv', vim.cmd.Ex, opts)
map('n', '<leader>w', '<cmd>w<CR>', opts)
map('n', '<leader>q', '<cmd>q<CR>', opts)

-- Telescope
map('n', '<leader>ff', '<cmd>Telescope find_files<cr>', opts)
map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', opts)
map('n', '<leader>fb', '<cmd>Telescope buffers<cr>', opts)
map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', opts)
map('n', '<leader>fs', '<cmd>Telescope git_status<cr>', opts)

-- LSP
map('n', 'gd', vim.lsp.buf.definition, opts)
map('n', 'gr', vim.lsp.buf.references, opts)
map('n', '<leader>rn', vim.lsp.buf.rename, opts)
map('n', 'K', vim.lsp.buf.hover, opts)
map('n', '<leader>f', vim.lsp.buf.format, opts)

-- Git (Fugitive)
map('n', '<leader>gs', vim.cmd.Git, opts)
map('n', '<leader>gd', vim.cmd.Gdiffsplit, opts)
map('n', '<leader>gp', function() vim.cmd.Git('pull') end, opts)
map('n', '<leader>gu', function() vim.cmd.Git('push') end, opts)
map('n', '<leader>gc', function() vim.cmd.Git('commit') end, opts)

-- Buffer management
map('n', '<leader>q', vim.cmd.bdelete, opts)
map('n', '<leader>n', vim.cmd.enew, opts)

-- Window navigation
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- Custom Copy Paste
map("v", "<C-c>", '"+y')             -- Copy in visual mode
map("v", "<C-x>", '"+d')             -- Cut in visual mode
map({ "i", "n" }, "<C-v>", "<C-r>+") -- Paste in insert mode

-- Move to start/end of line
map("n", "<leader>h", "0", opts)
map("n", "<leader>l", "$", opts)

-- Terminal keymaps
map('n', '<leader>t', ':terminal<CR>', opts) -- Open terminal from normal mode
map('t', '<Esc>', [[<C-\><C-n>]], opts)      -- Close terminal from terminal mode

-- Jump back to previous file
map('n', '<leader><leader><leader>', [[<C-^>]], opts)

-- show error --
map('n', '<leader>0', vim.diagnostic.open_float, { desc = 'Show diagnostic under cursor' })


-- LocalNest (AI) keymaps
local localnest_chat = require("localnest.chat")
local localnest_fim  = require("localnest.fim")

-- FIM: inline completion (Insert mode)
map("i", "<C-x>", function()
  localnest_fim.toggle()
end, vim.tbl_extend("force", opts, { desc = "LocalNest: Toggle FIM" }))

map("i", "<C-z>", function()
  localnest_fim.accept()
end, vim.tbl_extend("force", opts, { desc = "LocalNest: Accept FIM" }))

map("i", "<C-d>", function()
  localnest_fim.dismiss()
end, vim.tbl_extend("force", opts, { desc = "LocalNest: Dismiss FIM" }))

-- Grouped AI Commands (Leader and Ctrl-O)
local wk = require("which-key")

wk.add({
  { "<leader>a", group = "AI (LocalNest)" },
  -- Slash Commands
  { "<leader>ae", function() localnest_chat.slash("explain") end, desc = "Explain Code" },
  { "<leader>af", function() localnest_chat.slash("fix") end, desc = "Fix Code" },
  { "<leader>ar", function() localnest_chat.slash("refactor") end, desc = "Refactor Code" },
  { "<leader>at", function() localnest_chat.slash("test") end, desc = "Generate Tests" },
  
  -- DAP Keymaps (User version)
  { "<leader>d", group = "Debug" },
  { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
  { "<leader>ds", function() require("dap").continue() end, desc = "Debug Start/Continue" },
  { "<leader>dd", function() require("dap").step_over() end, desc = "Step Over" },
  { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
  { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
  { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
  { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },

  -- Aerial (Outline)
  { "<leader>o", "<cmd>AerialToggle! left<CR>", desc = "Code Outline" },

  -- Neotest
  { "<leader>t", group = "Test" },
  { "<leader>tt", function() require("neotest").run.run() end, desc = "Run Nearest Test" },
  { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run Current File" },
  { "<leader>ts", function() require("neotest").run.stop() end, desc = "Stop Test" },
  { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show Output" },

  -- LSP extensions
  { "gD", vim.lsp.buf.declaration, desc = "Go to Declaration" },
  { "gi", vim.lsp.buf.implementation, desc = "Go to Implementation" },
  { "gt", vim.lsp.buf.type_definition, desc = "Go to Type Definition" },

  -- Chat Commands
  { "<C-o>", group = "AI Chat" },
  { "<C-o>c", function()
    vim.ui.input({ prompt = "Chat with LocalNest: " }, function(input)
      if input and input ~= "" then localnest_chat.ask(input) end
    end)
  end, desc = "Open Chat" },
  { "<C-o>x", function() localnest_chat.ask_on_selection() end, desc = "Ask about Selection" },
  { "<C-o>f", function() localnest_chat.ask_on_file() end, desc = "Analyze File" },
  { "<C-o>t", function() localnest_chat.ask_inline() end, desc = "Ask via @this block" },
})

