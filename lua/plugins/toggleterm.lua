local map = require('core.utils').map
local M = {
  "akinsho/toggleterm.nvim",
  cmd = 'ToggleTerm',
}

M.init = function()
  vim.keymap.set('n', ',1', ":1TermExec cmd=''<Left>", { silent = false, noremap = true })
  vim.keymap.set('n', ',2', ":2TermExec cmd=''<Left>", { silent = false, noremap = true })
end

vim.api.nvim_create_user_command('QingdaoTerm',function()
  local Terminal = require('toggleterm.terminal').Terminal
  local qingdao_term = Terminal:new({ hidden = true, count = 1 })
  qingdao_term:toggle()
  qingdao_term:send("unset_proxy && clippy ssh qingdao")
end,{})

vim.api.nvim_create_user_command('Lazygit',function()
  local Terminal = require('toggleterm.terminal').Terminal
  local lazygit = Terminal:new({
    cmd = "lazygit",
    dir = "git_dir",
    direction = "float",
    float_opts = {
      border = "double",
    },
    on_open = function(term)
      vim.cmd("startinsert!")
      vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
    end,
    on_close = function(term)
      vim.cmd("startinsert!")
    end,
  })
  lazygit:toggle()
end,{})


M.config = function()
  require("toggleterm").setup{}
end

return M
