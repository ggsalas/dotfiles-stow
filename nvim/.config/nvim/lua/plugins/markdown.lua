return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    image = {
      enabled = true,
      doc = {
        enabled = false,
        max_width = 2000,
        max_height = 1500,
      },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    vim.keymap.set("n", "K", function()
      require("snacks").image.hover()
    end, { desc = "Image preview" })
  end,
}
