return {
  "kepano/flexoki-neovim",
  name = "flexoki",
  config = function(_, opts)
    require("flexoki").setup(opts)
    vim.opt.termguicolors = true
    vim.o.background = "light"
    vim.cmd("colorscheme flexoki-light")
    vim.opt.syntax = "enable"
    vim.opt.cursorline = true
    vim.opt.guicursor = "n-v-sm:block-Cursor,i-ci-ve:ver35-Cursor,c:ver100-Cursor,r-cr-o:hor20-Cursor,t:ver35-Cursor"

    -- theme colors
    local magenta = "#b20079"
    local cursor_fg = "#FFFCF0"
    local sline_fg = vim.api.nvim_get_hl(0, { name = "StatusLine" }).fg or 0x100F0F
    local slineNC_bg = vim.api.nvim_get_hl(0, { name = "StatusLineNC" }).bg or 0xE6E4D9
    local slineNC_fg = vim.api.nvim_get_hl(0, { name = "StatusLineNC" }).fg or 0x6F6E69
    local normal_fg = vim.api.nvim_get_hl(0, { name = "Normal" }).fg or 0x100F0F

    -- cursor
    vim.api.nvim_set_hl(0, "Cursor", { bg = magenta, fg = cursor_fg })
    vim.api.nvim_set_hl(0, "lCursor", { bg = magenta, fg = cursor_fg })
    vim.api.nvim_set_hl(0, "CursorIM", { bg = magenta, fg = cursor_fg })
    vim.api.nvim_set_hl(0, "TermCursor", { bg = magenta, fg = cursor_fg })

    -- lines
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = slineNC_bg, bg = "NONE" })

    -- tabline
    vim.api.nvim_set_hl(0, "TabLineFill", { fg = slineNC_fg, bg = slineNC_bg })

    -- fold
    vim.api.nvim_set_hl(0, "Folded", { fg = normal_fg, bg = "NONE" })
    vim.api.nvim_set_hl(0, "TabLine", { fg = slineNC_fg, bg = slineNC_bg, sp = slineNC_fg })
    vim.api.nvim_set_hl(0, "TabLineSel", { fg = sline_fg, bg = slineNC_bg, bold = true, sp = slineNC_fg })

    -- trasnsparent command line
    local highlights = {
      "Cmdline",
      "CmdlineBorder",
      "CmdlinePrompt",
      "MsgArea",
      "MsgSeparator",
      "ModeMsg",
      "MoreMsg",
      "ErrorMsg",
      "WarningMsg",
      "Question",
    }

    for _, group in ipairs(highlights) do
      vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
  end,
}
