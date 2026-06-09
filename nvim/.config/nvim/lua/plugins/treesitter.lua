return {
  -- treesitter (support textobjects, required for jsx)
  -----------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    version = "*",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      -- Fix nvim 0.12: match[id] now returns TSNode[] instead of TSNode.
      -- Override the directive to extract the first node from the list.
      local ts_query = require("vim.treesitter.query")
      local aliases = { ex = "elixir", pl = "perl", sh = "bash", uxn = "uxntal", ts = "typescript" }
      local function lang_from_info_string(alias)
        return vim.filetype.match({ filename = "a." .. alias }) or aliases[alias] or alias
      end
      ts_query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
        local nodes = match[pred[2]]
        if not nodes then
          return
        end
        -- In Neovim 0.12+, match[id] returns TSNode[] instead of TSNode
        local node = type(nodes) == "table" and nodes[1] or nodes
        if not node then
          return
        end
        metadata["injection.language"] = lang_from_info_string(vim.treesitter.get_node_text(node, bufnr):lower())
      end, { force = true, all = false })

      local config = require("nvim-treesitter.configs")
      ---@diagnostic disable-next-line: missing-fields
      config.setup({
        -- Add languages to be installed here that you want installed for treesitter
        ensure_installed = {
          "go",
          "lua",
          "python",
          "typescript",
          "javascript",
          "tsx",
          "php",
          "markdown",
          "markdown_inline",
          "sql",
          "html",
          "css",
          "scss",
          "json",
          "astro",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]m"] = "@function.outer",
            ["]]"] = "@class.inner",
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer",
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[["] = "@class.inner",
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer",
          },
        },
      })
    end,
  },
}
