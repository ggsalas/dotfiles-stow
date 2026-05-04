local spellBuffer = function()
  local config = vim.api.nvim_win_get_config(0)
  if config.relative ~= "" then
    return -- do not apply on floating windows
  end

  vim.opt_local.spell = true
  vim.opt_local.spelloptions:append("camel")
  vim.opt_local.spelloptions:append("noplainbuffer")
  vim.opt_local.spelllang = "en_us"
end

vim.api.nvim_create_autocmd("FileType", {
  callback = spellBuffer,
  pattern = {
    "c",
    "cpp",
    "go",
    "lua",
    "python",
    "rust",
    "tsx",
    "help",
    "php",
    "markdown",
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
  },
})
