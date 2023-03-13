local M = {}
local map = require("core.utils").map
local group = vim.api.nvim_create_augroup("KK",{clear=true}) -- {clear = true} will make sure that the autocmds will be hooked only once.
M.au = function(event,opt)
  if type(opt) == 'string' then
    opt = {command = opt}
  elseif type(opt) == 'function' then
    opt = {callback = opt}
  end
  local merged_opts = vim.tbl_extend('force',{group=group},opt)
  vim.api.nvim_create_autocmd(event,merged_opts)
end

M.au("FileType",{
  pattern='txt',
  command='if expand("%:t")=="pose.txt" | set ro | endif'
})

M.au('VimLeavePre',{
  callback = function ()
    treesitter_job:kill()
  end
})

-- NOTE: use utilyre/barbecue.nvim instead
-- M.au("VimEnter",{
--   callback = function()
--     require("contrib.winbar").create_winbar()
--   end
-- })
M.au("BufRead",{command="set foldlevel=99"})

-- -- how to find which pattern triggeres the autocmd? example here:
-- M.au("FileType",{,pattern="*",callback = function ()
--   local data = {
--     buf = vim.fn.expand('<abuf>'),
--     file = vim.fn.expand('<afile>'),
--     match = vim.fn.expand('<amatch>')} -- NOTE: amatch is we need
--   print(vim.inspect(data))
-- end})

local function setup_terminal()
  M.au("TermOpen",{
    command=[[ setlocal nonumber norelativenumber | setfiletype terminal ]],
    pattern="term://*",
  })

  M.au("FileType",{
    pattern = {"terminal","nvimgdb"},
    callback = function ()
      local buf = vim.api.nvim_get_current_buf()
      M.au("BufEnter",{
        callback = function ()
          vim.cmd [[startinsert]]
          map('n','cc', 'a<C-u>',{buffer=true})
          map('i','<C-w>h','<Esc><C-w>h',{buffer=true})
          map('i','<C-w>n','<Esc><C-w>j',{buffer=true})
          map('i','<C-w>e','<Esc><C-w>k',{buffer=true})
          map('i','<C-w>i','<Esc><C-w>l',{buffer=true})
          map('t','Q',[[<C-\><C-n>:q<CR>]],{buffer=true})
        end,
        buffer = buf
      })
      M.au("BufLeave",{
        callback=function ()
          vim.cmd [[stopinsert]]
        end,
        buffer=buf
      })
      vim.api.nvim_exec_autocmds('BufEnter',{group='KK'})
    end
  })
end
setup_terminal()

M.au("BufReadPost",{callback=function ()
  if vim.fn.line("'\"")>0 and vim.fn.line("'\"")<=vim.fn.line("$") then
    vim.cmd [[ exe "normal! g`\"" ]]
  end
end,desc="Return to last edit position when opening files (You want this!)"})

M.au("BufNew",{callback=function ()
  if vim.bo.ft~='TelescopePrompt' and
    string.match(vim.bo.buftype,[[prompt]]) 
    and vim.api.nvim_get_mode()['mode']~='i' 
    then
      vim.cmd [[ startinsert ]]
    end
  end,
})

M.au("BufEnter",{callback=function ()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_line_count(bufnr) > 3000 then
    vim.o.foldenable = false
    vim.b.indent_blankline_enabled = false -- NOTE: important for performance
  else
    vim.o.foldenable = true
    vim.o.foldmethod = "expr"
    vim.o.foldexpr = "nvim_treesitter#foldexpr()"
  end
end})

M.au('BufEnter',{callback=function ()
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(bufnr,'buftype')
  if buftype=='nofile' then
    map('n','q',':q<CR>',{buffer=bufnr})
  end
end})

M.au("CmdwinLeave",{callback=function ()
  require('cmp').close()
end})

vim.g.old_current_word = ""
vim.g.last_focused_win = nil
M.au("WinLeave",{callback=function ()
  local buf = vim.api.nvim_get_current_buf()
  vim.g.last_focused_win = vim.api.nvim_get_current_win()
  local ft = vim.api.nvim_buf_get_option(buf,'filetype')
  if not (string.match(ft,'Telescope')) then
    local start = vim.loop.hrtime()
    vim.g.old_current_word = vim.fn.expand('<cword>')
    local ok, err = pcall(function()
      vim.cmd(string.format(":call setreg('c','%s')",vim.g.old_current_word))
    end)
    if not ok then
      print("cannot set old_current_word")
    end
  end
end})
map("n","<C-w>l",function ()
  if vim.api.nvim_win_is_valid(vim.g.last_focused_win)then
    vim.api.nvim_set_current_win(vim.g.last_focused_win) 
  end
end)

M.au("BufEnter",{callback=function ()
  local is_dir = vim.fn.expand('%') == "."
  if is_dir then
    vim.cmd("NvimTreeClose")
    vim.cmd("NvimTreeOpen .")
  end
end})

_G.any_client_attached = function (bufnr)
  bufnr = bufnr or vim.fn.bufnr()
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

-- M.au("FileType",{pattern='lua',callback=function()
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


-- disable syntax in large file: maybe consume too much time
-- M.au("FileType",{callback=function ()
--   if vim.fn.wordcount()['bytes'] > 2048000 or vim.fn.line('$') > 5000 then
--     print("syntax off")
--     vim.cmd("setlocal syntax=off")
--   end
-- end})

M.ft_map = function(ft,mode,lhs,rhs,opts)
  M.au('FileType',{callback=function ()
    local merged_opts = vim.tbl_extend('force',{buffer=true},opts or {})
    map(mode,lhs,rhs,merged_opts)
  end,
    pattern=ft})
end

return M
