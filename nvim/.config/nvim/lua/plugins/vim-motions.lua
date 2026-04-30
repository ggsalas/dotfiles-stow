return {
  -- better vim motions
  ---------------------
  "ggandor/leap.nvim",
  dependencies = { "RRethy/nvim-base16" },
  config = function()
    local leap = require('leap')

    leap.opts.labels = 'jhkl;fgdsauyiopmn,./rtewqvbcxz'

    vim.keymap.set('n', 'f', '<Plug>(leap-forward-to)')
    vim.keymap.set('n', 't', '<Plug>(leap-forward-till)')
    vim.keymap.set('n', 'F', '<Plug>(leap-backward-to)')
    vim.keymap.set('n', 'T', '<Plug>(leap-backward-ill)')
  end
}
