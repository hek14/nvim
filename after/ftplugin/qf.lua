require('core.utils').map("n",'q',":q<CR>",{buffer=true})
require('core.utils').map('n','<C-p>',"<cmd>lua require('core.utils').preview_qf()<CR>",{buffer=true})
