return {
  "zbirenbaum/copilot.lua",
  event = "InsertEnter",
  opts = {
    suggestion = {
      enabled = true,
      auto_trigger = true,
      debounce = 15,
      keymap = {
        accept = "<C-y>",
        next = "<C-.>",
        prev = "<C-,>",
        dismiss = "<C-e>",
        trigger = "<C-]>",
      },
    },
    panel = {
      enabled = false,
    },
  },
  config = function(_, opts)
    require("copilot").setup(opts)

    vim.keymap.set("i", "<C-]>", function()
      require("copilot.suggestion").next()
    end, { silent = true })
  end,
}
