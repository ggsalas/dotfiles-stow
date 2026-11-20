local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Disable Nvim's builtin directory browser (0.13+); it sets 'nomodifiable' on dir buffers and breaks dirvish
vim.g.loaded_nvim_dir_plugin = 1

require("configs")
require("lazy").setup("plugins")
