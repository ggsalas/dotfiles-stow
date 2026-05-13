local spellBuffer = function()
  local config = vim.api.nvim_win_get_config(0)
  if config.relative ~= "" then
    return -- do not apply on floating windows
  end

  vim.opt_local.spell = true
  vim.opt_local.spelloptions:append("camel")
  vim.opt_local.spelloptions:append("noplainbuffer")
  vim.opt_local.spelllang = "en_us,es"
  vim.opt_local.spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add,"
    .. vim.fn.stdpath("config") .. "/spell/es.utf-8.add"
end

vim.keymap.set("n", "zg", function()
  local choice = vim.fn.confirm("Add word to which dictionary?", "&English\n&Spanish")
  if choice == 1 then
    vim.cmd("normal! 1zg")
  elseif choice == 2 then
    vim.cmd("normal! 2zg")
  end
end, { desc = "Add word to spellfile (choose language)" })

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
