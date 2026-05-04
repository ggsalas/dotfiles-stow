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
      -- Fix nvim 0.12: nodes in match results can be non-nil but with missing
      -- methods (e.g. `range`). Override the directive to guard against this.
      local ts_query = require("vim.treesitter.query")
      local aliases = { ex = "elixir", pl = "perl", sh = "bash", uxn = "uxntal", ts = "typescript" }
      local function lang_from_info_string(alias)
        return vim.filetype.match({ filename = "a." .. alias }) or aliases[alias] or alias
      end
      ts_query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
        local node = match[pred[2]]
        if not node or not node.range then
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
      })
    end,
  },
}
