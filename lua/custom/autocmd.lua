-- VimEnter event: just like ~/.config/nvim/after/plugin
-- group: set {clear = true} will make sure that the autocmds will be hooked only once.
local map = require('core.utils').map
local function setup_term()
  map('n','cc', 'a<C-u>',{buffer=true})
  map('i','<C-w>h','<Esc><C-w>h',{buffer=true})
  map('i','<C-w>n','<Esc><C-w>j',{buffer=true})
  map('i','<C-w>e','<Esc><C-w>k',{buffer=true})
  map('i','<C-w>i','<Esc><C-w>l',{buffer=true})
  map('t','Q',[[<C-\><C-n>:q<CR>]],{buffer=true})
end
local match = function(str,pattern)
  return string.len(vim.fn.matchstr(str,pattern))>0
end
local group = vim.api.nvim_create_augroup("KK",{clear=true})

vim.api.nvim_create_autocmd("BufRead",{command="set foldlevel=99",group=group})
vim.api.nvim_create_autocmd("FileType",{command="setlocal shiftwidth=2",group=group,pattern="lua"})

vim.api.nvim_create_autocmd("BufRead",{callback=function ()
  map("n","gm","<Cmd>lua require('contrib.treesitter.python').goto_python_main()<CR>",{buffer=true})
end, group=group, pattern="*.py"})

-- -- how to find the pattern we should use? example here: 
-- vim.api.nvim_create_autocmd("FileType",{group=group,pattern="*",callback = function ()
--   local data = {
--     buf = vim.fn.expand('<abuf>'), 
--     file = vim.fn.expand('<afile>'), 
--     match = vim.fn.expand('<amatch>')} 
--   -- amatch here is what we want. :help expand to see more info
--   print(vim.inspect(data))
-- end})

vim.api.nvim_create_autocmd("FileType",{callback=function ()
  map("n",'q',":q<CR>",{buffer=true})
  map('n','<C-p>',"<cmd>lua require('custom.utils').preview_qf()<CR>",{buffer=true})
end,group=group,pattern="qf"})

vim.api.nvim_create_autocmd({"BufWinEnter","BufEnter","WinEnter"},{callback=function ()
  if match(vim.o.ft,[[\(terminal\|floaterm\|nvimgdb\)]]) then
    setup_term()
    vim.cmd [[startinsert]]
    vim.api.nvim_create_autocmd("BufLeave",{callback=function ()
      vim.cmd [[stopinsert]]
    end,buffer=0,group=group})
  end
end,group=group})

vim.api.nvim_create_autocmd("BufReadPost",{callback=function ()
  if vim.fn.line("'\"")>0 and vim.fn.line("'\"")<=vim.fn.line("$") then
    vim.cmd [[ exe "normal! g`\"" ]]
  end
end,group=group,desc="Return to last edit position when opening files (You want this!)"})

vim.api.nvim_create_autocmd("User",{callback=function ()
  require("notify")('Packer Sucessful')
end,pattern={"PackerComplete","PackerCompileDone"},group=group})

vim.api.nvim_create_autocmd("BufNew",{callback=function ()
  if match(vim.o.buftype,[[prompt]]) then
    print("bufnew prompt")
    vim.cmd [[ startinsert ]]
  end
end,group=group})
