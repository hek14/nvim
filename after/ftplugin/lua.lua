vim.opt_local.shiftwidth = 2
vim.keymap.set("n","<leader>e",":<C-u>help <C-r><C-w><CR>",{noremap=true,silent=true,buffer=true})
vim.keymap.set('n', '<F8>', [[:lua require"dap".toggle_breakpoint()<CR>]], { noremap = true,buffer=true })
vim.keymap.set('n', '<F9>', [[:lua require"dap".continue()<CR>]], { noremap = true,buffer=true })
vim.keymap.set('n', '<F10>', [[:lua require"dap".step_over()<CR>]], { noremap = true,buffer=true })
vim.keymap.set('n', '<S-F10>', [[:lua require"dap".step_into()<CR>]], { noremap = true,buffer=true })
vim.keymap.set('n', '<F12>', [[:lua require"dap.ui.widgets".hover()<CR>]], { noremap = true,buffer=true })
vim.keymap.set('n', '<F5>', [[:lua require"osv".launch({port = 808,buffer=true6})<CR>]], { noremap = true,buffer=true })
