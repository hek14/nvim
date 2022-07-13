local timer = nil
local insert_mode_cancelled = false
local normal_mode_cancelled = false
local delay = 500
local function set_timer()
  if timer then
    print("clear existing timer")
    vim.loop.timer_stop(timer)
  end
  timer = vim.defer_fn(function()
    if vim.fn.mode()=='i' then
      if not insert_mode_cancelled then
        print("timer end")
        require('telescope.builtin').registers()
      else
        print('normal paste')
        local curr_row,curr_char = unpack(vim.api.nvim_win_get_cursor(0))
        local curr_line = vim.api.nvim_get_current_line()
        local last_char = curr_line:sub(curr_char,curr_char)
        local before_char = curr_line:sub(1,curr_char-1)
        local after_char = curr_line:sub(curr_char+1,-1)
        local to_paste = vim.fn.getreg(last_char)
        local after_paste = string.format([[%s%s%s]],before_char,to_paste,after_char)
        vim.api.nvim_set_current_line(after_paste)
        vim.api.nvim_win_set_cursor(0,{curr_row,curr_char+#to_paste-1})
      end
    else -- normal
      if not normal_mode_cancelled then
        print("timer end")
        require('telescope.builtin').registers()
      end
    end
    timer = nil
  end,delay)
end

local group = vim.api.nvim_create_augroup("kk_registers",{clear=true})
vim.keymap.set("i","<C-R>",function ()
  insert_mode_cancelled = false
  set_timer()
end,{noremap=true})
vim.keymap.set("n",'"',function ()
  normal_mode_cancelled = false
  set_timer()
end,{noremap=true})
vim.api.nvim_create_autocmd({"TextChangedI"},{callback=function ()
  if timer then
    insert_mode_cancelled = true
    print("insert_mode_cancelled")
  end
end,group=group})
vim.api.nvim_create_autocmd({"CursorMoved"},{callback=function ()
  if timer then
    normal_mode_cancelled = true
    print("normal_mode_cancelled")
  end
end,group=group})
