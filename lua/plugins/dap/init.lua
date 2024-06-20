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
    "nvim-neotest/nvim-nio",
    'mfussenegger/nvim-dap-python',
    'nvim-telescope/telescope-dap.nvim',
    {'rcarriga/cmp-dap',enabled = function()
      local ok, cmp = pcall(require,'cmp')
      return ok
    end},
    'jbyuki/one-small-step-for-vimkind',
  },
}

M.config = function()
  for _, ft_path in ipairs(vim.api.nvim_get_runtime_file('lua/plugins/dap/configs/*.lua', true)) do
    loadfile(ft_path)()
  end
  require('dap.ext.vscode').load_launchjs(nil, { cppdbg = {'c', 'cpp'}, debugpy = 'py' })
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
        size = 50,
        position = 'right',
      },
      {
        elements = {
          'repl',
        },
        size = 20,
        position = 'bottom',
      },
    },
  })

  -- Events Listeners
  local dap = require('dap')
  local ui = require("dapui")
  dap.listeners.before.attach.dapui_config = function()
    ui.open()
  end
  dap.listeners.before.launch.dapui_config = function()
    ui.open()
  end
  dap.listeners.before.event_terminated.dapui_config = function()
    ui.close()
  end
  dap.listeners.before.event_exited.dapui_config = function()
    ui.close()
  end

  require('telescope').load_extension('dap')
  local ok, cmp = pcall(require,'cmp')
  if ok then
    cmp.setup.filetype({ 'dap-repl', 'dapui_watches' }, {
      sources = require('cmp').config.sources({
        { name = 'dap' },
      }, {
        { name = 'buffer' },
      }),
    })
  end
end
return M
