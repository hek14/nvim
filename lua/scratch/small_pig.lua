local print = vim.print
local wb = vim.opt.winbar
local timer = vim.loop.new_timer()
local iter = 1
local max_cnt = 200
local gen_str = function()
  if(iter > vim.fn.winwidth(0))then
    iter = vim.fn.winwidth(0)
  end
  local ans = ""
  for i = 1,iter do
    ans = ans .. ' '
  end
  ans = ans .. "🐢" 
  return ans
end
timer:start(10, 20, vim.schedule_wrap(function()
  iter = (iter + 1) % math.min(max_cnt, vim.fn.winwidth(0))
  vim.api.nvim_set_option_value( 'winbar', gen_str(), { scope = 'global' })
  --vim.cmd [[redraw]]
end))

