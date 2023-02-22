vim.cmd[[set number]]
local group = vim.api.nvim_create_augroup('_lazy',{clear=true})
local timer = nil
local timer2 = nil
local not_loaded_line = nil
local buf = vim.api.nvim_get_current_buf()
local win = vim.api.nvim_get_current_win()
local win_width = vim.api.nvim_win_get_width(win)
local ns = vim.api.nvim_create_namespace("_lazy")

local where_not_loaded = function()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local lines = vim.api.nvim_buf_get_lines(buf,0,-1,false)
  for i,line in ipairs(lines) do 
    if string.match(line,'Not Loaded')~=nil then
      not_loaded_line = i
      break
    end
  end
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

pcall(where_not_loaded)
vim.api.nvim_create_autocmd("TextChanged",{
  callback = function ()
    if not timer then
      timer = vim.loop.new_timer()
      timer:start(10,0,vim.schedule_wrap(function ()
        pcall(where_not_loaded)
      end))
    end
  end,
  group = group,
  buffer = buf
})

local set_winbar = function ()
  if not_loaded_line then
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = cursor[1]
    if line < not_loaded_line then
      vim.api.nvim_set_option_value( "winbar", "Loaded", { scope = "local" })
    else
      vim.api.nvim_set_option_value( "winbar", "Not Loaded", { scope = "local" })
    end
  end
  if timer2 then
    timer2:stop()
    timer2:close()
    timer2 = nil
  end
end

local set_virtual_text = function ()
  if not_loaded_line then
    local cursor = vim.api.nvim_win_get_cursor(win)
    local line = cursor[1]
    if line < not_loaded_line then
      vim.api.nvim_buf_set_extmark(buf,ns,cursor[1]-1,cursor[2],{
        id = 1,
        virt_text = { { "Loaded","DiagnosticVirtualTextHint" } },
        virt_text_win_col = math.floor(win_width*0.5)
      })
    else
      vim.api.nvim_buf_set_extmark(buf,ns,cursor[1]-1,cursor[2],{
        id = 1,
        virt_text = { { "Not Loaded","DiagnosticVirtualTextError" } },
        virt_text_win_col = math.floor(win_width*0.5)
      })
    end
  end
  if timer2 then
    timer2:stop()
    timer2:close()
    timer2 = nil
  end
end

vim.api.nvim_create_autocmd(
{ "CursorMoved", "CursorHold" },
{
  group = group,
  buffer = buf,
  callback = function()
    timer2 = vim.loop.new_timer()
    timer2:start(10,0,vim.schedule_wrap(function ()
      pcall(set_virtual_text)
    end))
  end,
}
)

vim.api.nvim_create_autocmd("WinClosed",
{
  group = group,
  buffer = buf,
  callback = function ()
    print('Lazy closed')
    vim.api.nvim_buf_clear_namespace(buf,ns,0,-1) 
  end
})

local goto_plugin = function()
  local plugin = vim.fn.input('Goto plugin: ')
  local search_str = string.format([[/\c^[^a-zA-Z0-9]*\zs%s<CR>]],plugin)
  return search_str
end

vim.keymap.set('n','g/',goto_plugin,{
  silent = true,
  buffer = buf,
  noremap = true,
  expr = true,
})
