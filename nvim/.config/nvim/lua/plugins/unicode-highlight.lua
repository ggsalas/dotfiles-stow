return {
  {
    "racakenon/vscode-unicode-highlight.nvim",
    config = function()
      -- The plugin's debounced scan (vim.defer_fn) doesn't check buffer validity, so
      -- closing a buffer right after writing (e.g. :wq on COMMIT_EDITMSG) raises
      -- "Invalid buffer id". Scanning synchronously avoids the stale callback.
      -- The plugin's module is literally named "init" and auto-setups on load.
      require("init").setup({ debounce_ms = 0 })

      -- Ghostty gives U+2028/U+2029 width 0; Neovim gives them width 1. Draw an
      -- overlay over just these cells so the raw codepoint is never sent to the
      -- terminal (buffer bytes stay unchanged; works with conceallevel=0).
      -- Background: https://github.com/ghostty-org/ghostty/discussions/14821#discussioncomment-19157453
      local group = vim.api.nvim_create_augroup("unicode_line_separator", { clear = true })
      local namespace = vim.api.nvim_create_namespace("unicode_line_separator")
      -- The plugin has no public diagnostic hook; this is its diagnostic namespace
      -- name and user_data.codepoint contract (verified against its current source).
      local diagnostic_namespace = vim.api.nvim_create_namespace("unicode_highlight_diag")
      local separators = { [0x2028] = "\u{2028}", [0x2029] = "\u{2029}" }

      local function update_buffer(buf)
        if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
          return
        end
        local diagnostics = vim.diagnostic.get(buf, { namespace = diagnostic_namespace })
        vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
        for _, diagnostic in ipairs(diagnostics) do
          local cp = diagnostic.user_data and diagnostic.user_data.codepoint
          local character = separators[cp]
          if character then
            local line = vim.api.nvim_buf_get_lines(buf, diagnostic.lnum, diagnostic.lnum + 1, false)[1]
            local start_col, end_col = diagnostic.col, diagnostic.end_col
            -- Diagnostics can briefly outlive text edits; validate only these positions.
            if line and start_col >= 0 and end_col <= #line and line:sub(start_col + 1, end_col) == character then
              vim.api.nvim_buf_set_extmark(buf, namespace, diagnostic.lnum, start_col, {
                virt_text = { { "_", "WarningMsg" } },
                virt_text_pos = "overlay",
              })
            end
          end
        end
      end

      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        group = group,
        callback = function(args)
          update_buffer(args.buf)
        end,
      })
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        update_buffer(buf)
      end
    end,
  },
}
