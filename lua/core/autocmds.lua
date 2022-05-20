local group = vim.api.nvim_create_augroup("KK",{clear=true})
local au = function(event,opt)
  local merged_opts = vim.tbl_extend('force',{group=group},opt or {})
  vim.api.nvim_create_autocmd(event,merged_opts)
end
-- uncomment this if you want to open nvim with a dir
-- vim.cmd [[ autocmd BufEnter * if &buftype != "terminal" | lcd %:p:h | endif ]]

-- Don't show any numbers inside terminals
au("TermOpen",{
  command=[[ setlocal nonumber norelativenumber | setfiletype terminal ]],
  pattern="term://*",
})
-- Don't show status line on certain windows
au({"BufEnter","BufRead","BufWinEnter","FileType","WinEnter"},{
  callback = function ()
    require("core.utils").hide_statusline()
  end,
})
au("BufReadPost",{
  command=[[ if expand('%:p') !~# '\m/\.git/' && line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif ]],
})

au("Filetype",{
  pattern="python",
  command=[[ setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4 ]]
})
-- File extension specific tabbing
vim.cmd [[ autocmd Filetype python setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4 ]]
vim.cmd [[ autocmd Filetype python setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4 ]]

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

au("BufRead",{command="set foldlevel=99",})
au("FileType",{command="setlocal shiftwidth=2",pattern="lua"})
au("BufRead",{callback=function ()
  map("n","gm","<Cmd>lua require('contrib.treesitter.python').goto_python_main()<CR>",{buffer=true})
end,pattern="*.py"})

-- -- how to find the pattern we should use? example here:
-- au("FileType",{,pattern="*",callback = function ()
--   local data = {
--     buf = vim.fn.expand('<abuf>'),
--     file = vim.fn.expand('<afile>'),
--     match = vim.fn.expand('<amatch>')}
--   -- amatch here is what we want. :help expand to see more info
--   print(vim.inspect(data))
-- end})

au("FileType",{callback=function ()
  map("n",'q',":q<CR>",{buffer=true})
  map('n','<C-p>',"<cmd>lua require('core.utils').preview_qf()<CR>",{buffer=true})
end,pattern="qf"})

au({"BufWinEnter","BufEnter","WinEnter"},{callback=function ()
  if match(vim.o.ft,[[\(terminal\|floaterm\|nvimgdb\)]]) then
    setup_term()
    vim.cmd [[startinsert]]
    au("BufLeave",{callback=function ()
      vim.cmd [[stopinsert]]
    end,buffer=0,})
  end
end,})

au("BufReadPost",{callback=function ()
  if vim.fn.line("'\"")>0 and vim.fn.line("'\"")<=vim.fn.line("$") then
    vim.cmd [[ exe "normal! g`\"" ]]
  end
end,desc="Return to last edit position when opening files (You want this!)"})

au("User",{callback=function ()
  require("notify")('Packer Sucessful')
end,pattern={"PackerComplete","PackerCompileDone"},})

au("BufNew",{callback=function ()
  if match(vim.o.buftype,[[prompt]]) then
    print("bufnew prompt")
    vim.cmd [[ startinsert ]]
  end
end,})
