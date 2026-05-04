return {
  "sainnhe/everforest",
  name = "everforest",
  config = function()
    vim.g.everforest_background = "hard"
    vim.g.everforest_transparent_background = 1
    vim.g.everforest_cursor = "purple"
    vim.opt.termguicolors = true

    vim.cmd("colorscheme everforest")
  end,
}
