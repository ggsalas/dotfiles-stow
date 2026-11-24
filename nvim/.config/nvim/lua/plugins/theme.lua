-- Omarchy manages the colours itself (and changes them live), so use its theme
-- plugin there. Everywhere else (macOS) use everforest.
-- Same check omarchy-theme.nvim uses to know it is running on Omarchy.
local is_omarchy = vim.uv.fs_stat(vim.fn.expand("~/.local/state/omarchy/current/theme.name")) ~= nil

if is_omarchy then
  return {
    "EskelinenAntti/omarchy-theme.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("omarchy")
    end,
  }
end

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
