local map = require("core.utils").map

-- NOTE: the callback function in autocmd accept one argument: event
-- the event is a table: {buf = xxx, data = xxx}, it is different for each event.
-- the old way is to use <abuf>: buf = vim.fn.expand('<abuf>'),
--                               file = vim.fn.expand('<afile>'),
--                               match = vim.fn.expand('<amatch>')}

local function writeToFile(filePath, content)
    -- Open the file in write mode
    local file, err = io.open(filePath, "w")
    if not file then
        error("Failed to open file: " .. err)
    end

    -- Write the content to the file
    file:write(content)

    -- Close the file
    file:close()
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  desc = "write the current cwd",
  group = vim.api.nvim_create_augroup('kk-vimleave', { clear = true }),
  callback = function()
    local filePath = "/tmp/cwd.txt"
    local content = vim.uv.cwd()
    writeToFile(filePath, content)
  end
})

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kk-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("FileType",{
  desc = "Do not edit pose.txt",
  pattern='txt',
  command='if expand("%:t")=="pose.txt" | set ro | endif'
})

vim.api.nvim_create_autocmd("TermOpen",{
  group = vim.api.nvim_create_augroup('kk-terminal', { clear = true }),
  command=[[ setlocal nonumber norelativenumber | setfiletype terminal ]],
  pattern="term://*",
})

vim.api.nvim_create_autocmd("FileType",{
  pattern = {"terminal","nvimgdb"},
  group = vim.api.nvim_create_augroup('kk-terminal', { clear = true }),
  callback = function ()
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_create_autocmd("BufEnter",{
      group = "kk-terminal",
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
    vim.api.nvim_create_autocmd("BufLeave",{
      callback=function ()
        vim.cmd [[stopinsert]]
      end,
      buffer=buf
    })
    vim.api.nvim_exec_autocmds('BufEnter',{group='kk-terminal'})
  end
})

vim.api.nvim_create_autocmd("BufReadPost",{
  desc="Return to last edit position when opening files",
  callback=function ()
    if vim.fn.line("'\"")>0 and vim.fn.line("'\"")<=vim.fn.line("$") then
      vim.cmd [[ exe "normal! g`\"" ]]
    end
  end
})

vim.api.nvim_create_autocmd('BufEnter',{
  callback=function ()
    local bufnr = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_buf_get_option(bufnr,'buftype')
    if buftype=='nofile' then
      map('n','q',':q<CR>',{buffer=bufnr})
    end
  end
})

vim.g.current_word = ""
vim.g.last_focused_win = nil
vim.api.nvim_create_autocmd("WinLeave",{
  callback=function ()
    pcall(function()
      local buf = vim.api.nvim_get_current_buf()
      vim.g.last_focused_win = vim.api.nvim_get_current_win()
      local ft = vim.api.nvim_buf_get_option(buf,'filetype')
      if not (string.match(ft,'Telescope')) then
        vim.g.current_word = vim.fn.expand('<cword>')
        vim.cmd(string.format(":call setreg('c','%s')",vim.g.current_word))
      end
    end)
  end
})

map("n","<C-w>l", function ()
  if vim.api.nvim_win_is_valid(vim.g.last_focused_win)then
    vim.api.nvim_set_current_win(vim.g.last_focused_win)
  end
end)

vim.api.nvim_create_autocmd("BufEnter",{
  callback=function ()
    local ok, _ = require("nvim-tree")
    if ok then
      local is_dir = vim.fn.expand('%') == "."
      if is_dir then
        vim.cmd("NvimTreeClose")
        vim.cmd("NvimTreeOpen .")
      end
    end
  end
})

-- disable syntax in large file: maybe consume too much time
vim.api.nvim_create_autocmd("FileType",{
  callback=function ()
    if vim.fn.wordcount()['bytes'] > 2048000 or vim.fn.line('$') > 5000 then
      print("syntax off for performance")
      vim.cmd("setlocal syntax=off")
    end
  end
})

vim.api.nvim_create_autocmd({"BufNewFile","BufRead"}, {
  callback = function()
    vim.cmd [[setfiletype tmux]]
  end,
  pattern = "*.conf"
})
