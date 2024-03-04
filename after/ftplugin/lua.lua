vim.opt_local.shiftwidth = 2
vim.keymap.set("n","<leader>e",":<C-u>help <C-r><C-w><CR>",{noremap=true,silent=true,buffer=true})
vim.keymap.set("n","<leader>so", "<Cmd>lua require('core.utils').source_curr_file()<cr>", {noremap=true,silent=true,buffer=true})
