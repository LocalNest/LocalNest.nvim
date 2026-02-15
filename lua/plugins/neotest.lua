require("neotest").setup({
  adapters = {
    require("neotest-go"),
    require("neotest-rust"),
    require("neotest-python")({
      dap = { adapter = "python" },
    }),
  },
})
