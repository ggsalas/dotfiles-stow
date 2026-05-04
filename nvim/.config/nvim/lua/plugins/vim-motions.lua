return {
  -- better vim motions
  ---------------------
  "https://codeberg.org/andyg/leap.nvim",
  config = function()
    local leap = require("leap")

    leap.opts.labels = "jhkl;fgdsauyiopmn,./rtewqvbcxz"

    vim.keymap.set({ "n", "x", "o" }, "f", "<Plug>(leap)")
    vim.keymap.set({ "n", "x", "o" }, "F", "<Plug>(leap-backward)")
    vim.keymap.set({ "n", "x", "o" }, "t", "<Plug>(leap-forward-till)")
    vim.keymap.set({ "n", "x", "o" }, "T", "<Plug>(leap-backward-till)")
  end,
}
