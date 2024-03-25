require('core.utils').map("n",'q',":q<CR>",{buffer=true, silent=true})
require('core.utils').map('n','<leader>p',"<cmd>lua require('core.utils').preview_qf()<CR>",{buffer=true, silent=true})
