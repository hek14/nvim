local M = {}
local map = require("core.utils").map
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
au("FileType",{
  pattern="lua",
  command="setlocal shiftwidth=2"
})
au("FileType",{
  pattern='txt',
  command= 'if expand("%:t")=="pose.txt" | set ro | endif'
})

-- VimEnter event: just like ~/.config/nvim/after/plugin
-- group: set {clear = true} will make sure that the autocmds will be hooked only once.
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
au("BufEnter",{callback=function ()
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
    end,buffer=vim.fn.bufnr(),})
  end
end,})

au("BufReadPost",{callback=function ()
  if vim.fn.line("'\"")>0 and vim.fn.line("'\"")<=vim.fn.line("$") then
    vim.cmd [[ exe "normal! g`\"" ]]
  end
end,desc="Return to last edit position when opening files (You want this!)"})


au("BufNew",{callback=function ()
  if vim.bo.ft~='TelescopePrompt' then --NOTE: telescope already do this
    if match(vim.bo.buftype,[[prompt]]) and vim.api.nvim_get_mode()['mode']~='i' then
      vim.cmd [[ startinsert ]]
    end
  end
end,})

_G.any_client_attached = function ()
  local bufnr = vim.fn.bufnr()
  -- local clients = vim.lsp.get_active_clients()
  -- local attached = {}
  -- for i,client in ipairs(clients) do
  --   if vim.lsp.buf_is_attached(bufnr,client.id) then
  --     table.insert(attached,{id=client.id,name=client.name})
  --   end
  -- end
  local attached = {}
  local clients = vim.lsp.buf_get_clients(bufnr) or {}
  for id,client in pairs(clients) do
    if client.name~='null-ls' then
      table.insert(attached,{id=id,name=client.name})
    end
  end
  return attached
end

-- au("FileType",{pattern='lua',callback=function()
--   if vim.bo.buflisted then
--     vim.defer_fn(function()
--       local attached_clients = any_client_attached()
--       if #attached_clients == 0 or (#attached_clients==1 and attached_clients[1].name=='null-ls') then
--         vim.cmd [[echohl WarningMsg]]
--         vim.cmd [[echo 'Manually start lsp']]
--         vim.cmd [[echohl None]]
--         vim.defer_fn(function()
--           vim.cmd [[LspStart]]
--         end,0)
--       end
--     end,50)
--   end
-- end})


-- disable syntax in large file
au("FileType",{callback=function ()
  if vim.fn.wordcount()['bytes'] > 2048000 or vim.fn.line('$') > 5000 then
    print("syntax off")
    vim.cmd("setlocal syntax=off")
  end
end})

au("FileType",{callback=function ()
  vim.defer_fn(function()
    print('should override vimtex')
    pcall(function ()
      vim.cmd [[
      xunmap <buffer> ic
      xunmap <buffer> ie
      xunmap <buffer> im
      xunmap <buffer> iP
      xunmap <buffer> i$
      xunmap <buffer> id
      nunmap <buffer> ]c
      nunmap <buffer> [c
      nmap <buffer> ,t  :VimtexCompileSS<CR>
      nmap <buffer> ,v  :VimtexView<CR>
      ]]
    end)
  end,50)
end,pattern='tex'})

M.ft_map = function(ft,mode,lhs,rhs,opts)
  au('FileType',{callback=function ()
    local merged_opts = vim.tbl_extend('force',{buffer=true},opts or {})
    map(mode,lhs,rhs,merged_opts)
  end,
    pattern=ft})
end

return M
