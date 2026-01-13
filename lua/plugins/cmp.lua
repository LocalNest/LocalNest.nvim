local cmp = require('cmp')

cmp.setup({
  preselect = cmp.PreselectMode.None,
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    }),
    -- manual Minuet trigger
    ['<A-y>'] = require('minuet').make_cmp_map(),  -- Alt-y
  }),
  sources = cmp.config.sources({
    -- give Minuet high priority, ahead of LSP
    { name = 'minuet', group_index = 1, priority = 100 },
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'path' },
    { name = 'buffer' },
  }),
  performance = {
    -- recommended to avoid timeouts with LLM backends
    fetching_timeout = 2000,
  },
})

cmp.setup.filetype('capnp', {
  enabled = false,
})
