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

-- Sugerencias "may be converted to TypeScript": los proyectos usan JS + JSDoc.
local IGNORED_TS_CODES = {
  [80001] = true, -- File is a CommonJS module; it may be converted to an ES module
  [80002] = true, -- This constructor function may be converted to a class declaration
  [80004] = true, -- JSDoc types may be moved to TypeScript types
  [80005] = true, -- 'require' call may be converted to an import
  [80006] = true, -- This may be converted to an async function
  [80009] = true, -- JSDoc typedef may be converted to TypeScript type
}

local set_diagnostics = vim.diagnostic.set
vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
  diagnostics = vim.tbl_filter(function(diagnostic)
    return not IGNORED_TS_CODES[tonumber(diagnostic.code)]
  end, diagnostics or {})

  return set_diagnostics(namespace, bufnr, diagnostics, opts)
end

vim.diagnostic.config(config)
