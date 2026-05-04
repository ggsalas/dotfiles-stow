vim.keymap.set("t", "jk", "<C-\\><C-n>")

vim.keymap.set("n", "<leader>tet", ":tabnew | terminal<cr>", { desc = "New terminal tab" })
vim.keymap.set("n", "<leader>tev", ":botright vsp term://zsh<cr>")
vim.keymap.set("n", "<leader>tes", ":botright sp term://zsh<cr>")

local terminal_mode = vim.api.nvim_create_augroup("terminal_mode", { clear = true })

local opts = { noremap = true, silent = true }

vim.api.nvim_create_autocmd("TermOpen", {
  command = ":startinsert",
  group = terminal_mode,
})

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.api.nvim_buf_set_keymap(0, "n", "gq", ":bd!<cr>", opts)
  end,
  group = terminal_mode,
})

vim.api.nvim_create_autocmd("TermOpen", {
  command = ":setlocal nonumber nocursorline",
  group = terminal_mode,
})
