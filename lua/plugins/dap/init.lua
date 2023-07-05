local group = vim.api.nvim_create_augroup('kk_dap',{clear=true})
local M = {
  'mfussenegger/nvim-dap',
  keys = {
    -- { '<leader>b', ':lua require"dap".toggle_breakpoint()<CR>' },
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
  require('dap.ext.vscode').load_launchjs(nil, { cppdbg = {'c', 'cpp'} })
  require('nvim-dap-virtual-text').setup({})
  require('dapui').setup({
    mappings = {
      expand = { '<CR>', '<2-LeftMouse>' },
      open = 'o',
      remove = 'd',
      edit = '<C-e>',
      repl = 'r',
    },
    -- icons = { expanded = '▾', collapsed = '▸' },
    -- layouts = {
    --   {
    --     elements = {
    --       'scopes',
    --       'breakpoints',
    --       'stacks',
    --       'watches',
    --     },
    --     size = 80,
    --     position = 'right',
    --   },
    --   {
    --     elements = {
    --       'repl',
    --       'console',
    --     },
    --     size = 10,
    --     position = 'bottom',
    --   },
    -- },
  })

  -- Events Listeners
  local dap = require('dap')
  local keymaps = {
    ['i'] = {
      {"<C-w>h","<Esc><C-w>h"},
      {"<C-w>n","<Esc><C-w>j"},
      {"<C-w>e","<Esc><C-w>k"},
      {"<C-w>i","<Esc><C-w>l"},
      {"<C-LEFT>","<Esc><C-w>h"},
      {"<C-DOWN>","<Esc><C-w>j"},
      {"<C-UP>","<Esc><C-w>k"},
      {"<C-RIGHT>","<Esc><C-w>l"},
      {"<C-w>l",function ()
        if vim.api.nvim_win_is_valid(vim.g.last_focused_win)then
          vim.api.nvim_set_current_win(vim.g.last_focused_win) 
          local ft = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(vim.g.last_focused_win), 'filetype')
          if ft == 'dap-repl' or ft == 'dapui_watches' then
            print('is dap')
            vim.cmd [[startinsert]]
          end
        end
      end}
    }
  }
  dap.listeners.after.event_initialized['dapui_config'] = function()
    print('dap event_initialized')
    require('dapui').open()
    local wins = vim.api.nvim_list_wins()
    local target = nil
    local curr_win = vim.api.nvim_get_current_win()
    for _,win in ipairs(wins) do
      vim.api.nvim_win_call(win,function ()
        local buffer = vim.api.nvim_win_get_buf(win)
        local filetype = vim.api.nvim_buf_get_option(buffer, 'filetype')
        if filetype:match('dap') then
          if "dap-repl"==filetype then
            target = win
            vim.g.dap_repl_buffer = vim.api.nvim_win_get_buf(win)
          end
          if filetype=="dap-repl" or filetype=='dapui_watches' then
            vim.api.nvim_create_autocmd({'BufWinEnter','WinEnter'}, {command='startinsert',group=group,buffer=buffer})
            vim.api.nvim_create_autocmd({'WinLeave'}, {command='stopinsert',group=group,buffer=buffer})
          end
          for mode, maps in pairs(keymaps) do
            for i, mapargs in ipairs(maps) do
              vim.keymap.set(mode, mapargs[1], mapargs[2], {noremap=true,silent=true,buffer=buffer})
            end
          end
        end
      end)
    end
    if target then
      vim.api.nvim_set_current_win(target)
    end
  end
  dap.listeners.before.event_terminated['dapui_config'] = function()
    require('dapui').close()
    vim.schedule(function()
      vim.cmd [[stopinsert]]
      pcall(function ()
        vim.cmd (string.format('bwipe! %s',vim.g.dap_repl_buffer))
      end)
    end)
  end
  dap.listeners.before.event_exited['dapui_config'] = function()
    require('dapui').close()
    vim.schedule(function()
      vim.cmd [[stopinsert]]
      pcall(function ()
        vim.cmd (string.format('bwipe! %s',vim.g.dap_repl_buffer))
      end)
    end)
  end
  dap.listeners.before.disconnect['dapui_config'] = function()
    require('dapui').close()
    vim.schedule(function()
      vim.cmd [[stopinsert]]
      pcall(function ()
        vim.cmd (string.format('bwipe! %s',vim.g.dap_repl_buffer))
      end)
    end)
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
end
return M
