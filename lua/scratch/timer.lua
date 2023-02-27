local M = {sleep = 1000, timer = nil}

function M.down()
    print(M.sleep)
    M.timer = vim.loop.new_timer()
    M.timer:start(1000, M.sleep, vim.schedule_wrap(function()
      local down = vim.api.nvim_replace_termcodes('normal <C-E>', true, true, true)
      vim.cmd(down)
    end))
end

function M.down_stop()
  if M.timer ~= nil then
    M.timer:close()
    M.timer = nil
  end
end

function M.down_slower()
  M.down_change(2)
end

function M.down_faster()
  M.down_change(0.5)
end

function M.down_change(n)
  M.down_stop()
  M.sleep = M.sleep*n
  M.down()
end


local kind = 'warning'
local warning_hlgroup = 'WarningMsg'
local hlgroup = warning_hlgroup
local chunks = {
  { kind .. ': ', hlgroup },
  { 'whatTHE' }
}
-- vim.pretty_print(chunks)

vim.api.nvim_echo(chunks, false, {})
