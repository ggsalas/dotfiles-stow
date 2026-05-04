-- Custom tabline: [number] filename | separators

function _G.custom_tabline()
  local s = ""
  local current = vim.fn.tabpagenr()
  local total = vim.fn.tabpagenr("$")
  for i = 1, total do
    local buflist = vim.fn.tabpagebuflist(i)
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = buflist[winnr]
    local name = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":t")
    if name == "" then
      name = "No Name"
    end
    local hl = i == current and "%#TabLineSel#" or "%#TabLine#"
    s = s .. hl .. " " .. i .. ":" .. name .. " "
    if i < total then
      s = s .. "%#TabLine#|"
    end
  end
  s = s .. "%#TabLineFill#%=%#TabLine#%999XX"
  return s
end
vim.o.tabline = "%!v:lua.custom_tabline()"
