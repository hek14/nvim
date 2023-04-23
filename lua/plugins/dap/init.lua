local M = {
  'mfussenegger/nvim-dap',
  keys = {
    { '<leader>b', ':lua require"dap".toggle_breakpoint()<CR>' },
    { '<leader>B', 
      ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>" 
    },
    {
      '<leader>lp',
      ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>",
    },
    { '<F3>', function()
      local ft = vim.api.nvim_buf_get_option(0, 'filetype')
      if ft == 'lua' then
        require"osv".launch({port = 8086})
        return
      end
      print('not nlua')
    end},
    { '<F4>', ':lua require"dap".run_last()<CR>'}, 
    { '<F5>', ':lua require"dap".continue()<CR>' },
    { '<F6>', ':lua require"dap".run_to_cursor()<CR>' },
    { '<F7>', "<cmd>lua require'dapui'.toggle()<CR>" },
    { '<F8>', ':lua require"dap".toggle_breakpoint()<CR>' },
    { '<F10>', ':lua require"dap".step_over()<CR>' },
    { '<F11>', ':lua require"dap".step_into()<CR>' },
    { '<F12>', ':lua require"dap".step_out()<CR>' },
    { '<leader>dn', ':lua require"dap".down()<CR>' },
    { '<leader>de', ':lua require"dap".up()<CR>' },
    { '<leader>ds', ':Telescope dap configurations<CR>' },
    { '<leader><F5>', 'lua require"dap".run_last()<CR>' },
    { '<leader>dq', ':lua require"dap".terminate()<CR>:lua require("dapui").close()<CR>' },
    { '<leader>dr', ':lua require"dap".repl.toggle({},"10 split")<CR>' },
    { '<leader>di', ':lua require"dap.ui.widgets".hover()<CR>' },
    {
      '<leader>d?',
      ':lua local widgets=require"dap.ui.widgets";widgets.centered_float(widgets.scopes)<CR>',
    },
    { '<leader>dc', ':Telescope dap commands<CR>' },
    { '<leader>db', ':Telescope dap list_breakpoints<CR>' },
  },
  dependencies = {
    'theHamsta/nvim-dap-virtual-text',
    'rcarriga/nvim-dap-ui',
    'mfussenegger/nvim-dap-python',
    'nvim-telescope/telescope-dap.nvim',
    'rcarriga/cmp-dap',
    'jbyuki/one-small-step-for-vimkind',
  },
}

M.config = function()
  for _, ft_path in ipairs(vim.api.nvim_get_runtime_file('lua/plugins/dap/configs/*.lua', true)) do
    loadfile(ft_path)()
  end
  require('nvim-dap-virtual-text').setup({})
  require('dapui').setup({
    mappings = {
      expand = { '<CR>', '<2-LeftMouse>' },
      open = 'o',
      remove = 'd',
      edit = '<C-e>',
      repl = 'r',
    },
    icons = { expanded = '▾', collapsed = '▸' },
    layouts = {
      {
        elements = {
          'scopes',
          'breakpoints',
          'stacks',
          'watches',
        },
        size = 80,
        position = 'right',
      },
      {
        elements = {
          'repl',
          'console',
        },
        size = 10,
        position = 'bottom',
      },
    },
  })

  -- Events Listeners
  local dap = require('dap')
  dap.listeners.after.event_initialized['dapui_config'] = function()
    require('dapui').open()
  end
  dap.listeners.before.event_terminated['dapui_config'] = function()
    require('dapui').close()
  end
  dap.listeners.before.event_exited['dapui_config'] = function()
    require('dapui').close()
  end
  dap.listeners.before.disconnect['dapui_config'] = function()
    require('dapui').close()
  end

  require('telescope').load_extension('dap')
  require('cmp').setup.filetype({ 'dap-repl', 'dapui_watches' }, {
    sources = require('cmp').config.sources({
      { name = 'dap' },
    }, {
      { name = 'buffer' },
    }),
  })

  local function focus_hover()
    local found = nil
    for win = 1, vim.fn.winnr('$') do
      local winid = vim.fn.win_getid(win)
      local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winid))
      local config = vim.api.nvim_win_get_config(winid)
      if config['focusable'] and config['relative'] ~= '' then
        --  and bufname=='DAP Hover'
        found = win
        break
      end
    end
    return found
  end

  require('core.utils').map('n', ',e', function()
    local found_hover = focus_hover()
    if found_hover ~= nil then
      return string.format([[:<C-u>%s wincmd w<CR>]], found_hover)
    else
      return [[:<C-u>lua require('dapui').eval()<Left>]]
    end
  end, { expr = true })

  require('core.utils').map('x', ',e', function()
    local found_hover = focus_hover()
    if found_hover ~= nil then
      return string.format([[:<C-u>%s wincmd w<CR>]], found_hover)
    else
      return [[:<C-u>lua require('dapui').eval()<CR>]]
    end
  end, { expr = true })

  -- autocmd
  local group = vim.api.nvim_create_augroup('kk_dap',{clear=true})
  local au = function(event, opts)
    vim.api.nvim_create_autocmd(event, vim.tbl_extend('force',opts,{group=group}))
  end
  -- au('FileType',{
  --   pattern = 'dap-repl',
  --   callback = require('dap.ext.autocompl').attach
  -- })
  au({'BufWinEnter','WinEnter'},{
    callback = function ()
      local buffer = vim.api.nvim_get_current_buf()
      local ft = vim.api.nvim_buf_get_option(buffer,'filetype')
      if ft=='dap-repl' then
        vim.cmd [[ startinsert ]]
        vim.keymap.map("i","<C-w>l",function ()
          if vim.api.nvim_win_is_valid(vim.g.last_focused_win)then
            vim.api.nvim_set_current_win(vim.g.last_focused_win) 
          end
        end,{buffer=buffer})
        vim.keymap.set("i","<C-w>h","<Esc><C-w>h<CR>",{noremap=true,silent=true,buffer=buffer})
        vim.keymap.set("i","<C-w>n","<Esc><C-w>j<CR>",{noremap=true,silent=true,buffer=buffer})
        vim.keymap.set("i","<C-w>e","<Esc><C-w>k<CR>",{noremap=true,silent=true,buffer=buffer})
        vim.keymap.set("i","<C-w>i","<Esc><C-w>l<CR>",{noremap=true,silent=true,buffer=buffer})
        vim.keymap.set("i","<C-LEFT>","<Esc><C-w>h<CR>",{noremap=true,silent=true,buffer=buffer})
        vim.keymap.set("i","<C-DOWN>","<Esc><C-w>j<CR>",{noremap=true,silent=true,buffer=buffer})
        vim.keymap.set("i","<C-UP>","<Esc><C-w>k<CR>",{noremap=true,silent=true,buffer=buffer})
        vim.keymap.set("i","<C-RIGHT>","<Esc><C-w>l<CR>",{noremap=true,silent=true,buffer=buffer})
      end
    end
  })
  au("WinLeave",{
    callback = function ()
      local buffer = vim.api.nvim_get_current_buf()
      local ft = vim.api.nvim_buf_get_option(buffer,'filetype')
      if ft=='dap-repl' then
        vim.cmd [[ stopinsert ]]
      end
    end
  })

end
return M
