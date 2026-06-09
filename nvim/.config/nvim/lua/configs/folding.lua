function FoldStyle()
  local foldstart = vim.v.foldstart
  local foldend = vim.v.foldend
  local line = vim.fn.getline(foldstart)

  -- if fold starts with ``` (code block), show the second line instead
  if line:match("^%s*```") then
    line = vim.fn.getline(foldstart + 1)
  end
  -- if fold starts with ```# %% (Jupiter code block), show the second line instead
  if line:match("^%s*# %%") then
    line = vim.fn.getline(foldstart + 1)
  end

  local tabstop = vim.bo.tabstop
  line = line:gsub("\t", string.rep(" ", tabstop))
  line = line:sub(1, 60)

  local nucolwidth = vim.wo.foldcolumn + (vim.wo.number and vim.wo.numberwidth or 0)
  local windowwidth = vim.fn.winwidth(0) - nucolwidth - 3
  local foldedlinecount = (foldend - foldstart + 1) .. " lines"

  local textwidth = #line + #foldedlinecount + 3
  local fillchars = windowwidth - textwidth

  return line .. string.rep(".", fillchars) .. " " .. foldedlinecount .. " ▼ "
end

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = "v:lua.FoldStyle()"
vim.opt.foldlevel = 99

vim.api.nvim_create_user_command("FoldSyntax", function()
  vim.opt.foldmethod = "syntax"
  vim.opt.foldlevel = 0
end, {})

vim.api.nvim_create_user_command("FoldExpr", function()
  vim.opt.foldmethod = "expr"
  vim.opt.foldlevel = 0
end, {})

vim.api.nvim_create_user_command("FoldManual", function()
  vim.opt.foldmethod = "manual"
  vim.opt.foldlevel = 0
end, {})

vim.api.nvim_create_user_command("FoldDiff", function()
  vim.opt.foldmethod = "diff"
  vim.opt.foldlevel = 0
end, {})

local function setup_jupiter_folding()
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "getline(v:lnum)=~'^# %%' ? '>1' : getline(v:lnum-1)=~'^# %%' ? 1 : '='"
  vim.opt.foldlevel = 0
end

vim.api.nvim_create_user_command("FoldJupiter", setup_jupiter_folding, {})

vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function()
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo.foldtext = "v:lua.FoldStyle()"
    vim.wo.foldlevel = 99
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("n", "<Tab>", "zA", { buffer = true, desc = "Toggle fold recursive" })
  end,
})
