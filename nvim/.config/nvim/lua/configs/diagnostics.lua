local config = {
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✖",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "ℹ",
    },
  },
  update_in_insert = true,
  underline = false,
  severity_sort = true,
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
}

vim.diagnostic.config(config)
