local dap = require('dap')
local g = vim.g
local map = require('core.utils').map
require('dap-python').setup(vim.fn.system("which python"):gsub('\n',''),{console = 'internalConsole'})
-- require('dap').set_log_level('INFO')
dap.defaults.fallback.terminal_win_cmd = '80vsplit new'
vim.fn.sign_define('DapBreakpoint', {text='🟥', texthl='', linehl='', numhl=''})
vim.fn.sign_define('DapBreakpointRejected', {text='🟦', texthl='', linehl='', numhl=''})
vim.fn.sign_define('DapStopped', {text='⭐️', texthl='', linehl='', numhl=''})

-- _G.shutDownDapSession = function()
--   local dap = require'dap'
--   dap.terminate()
--   dap.disconnect( { terminateDebuggee = true })
--   dap.close()
-- end

vim.api.nvim_del_keymap("n","<leader>bm")
map('n', '<leader>b', ':lua require"dap".toggle_breakpoint()<CR>')
map('n', '<leader>B', ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
map('n', '<leader>lp',":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
map('n', '<F12>', ':lua require"dap".step_out()<CR>')
map('n', '<F11>', ':lua require"dap".step_into()<CR>')
map('n', '<F10>', ':lua require"dap".step_over()<CR>')
map('n', '<F5>', ':lua require"dap".continue()<CR>:lua require"dap".repl.toggle({},"10 split")<CR><C-w>ji')
map('n', '<leader>dt', ':lua require"dap".run_to_cursor()<CR>')
map('n', '<leader>dn', ':lua require"dap".down()<CR>')
map('n', '<leader>de', ':lua require"dap".up()<CR>')
map('n', '<leader>dq', ':lua require"dap".stop()<CR>')
map('n', '<leader>dr', ':lua require"dap".repl.toggle({},"10 split")<CR><C-w>ji')
map('n', '<leader>di', ':lua require"dap.ui.widgets".hover()<CR>')
map('n', '<leader>d?', ':lua local widgets=require"dap.ui.widgets";widgets.centered_float(widgets.scopes)<CR>')

-- nvim-telescope/telescope-dap.nvim
require('telescope').load_extension('dap')
map('n', '<leader>ds', ':Telescope dap frames<CR>')
map('n', '<leader>dc', ':Telescope dap commands<CR>')
map('n', '<leader>db', ':Telescope dap list_breakpoints<CR>')
vim.cmd [[  au FileType dap-repl lua require('dap.ext.autocompl').attach() ]]

-- theHamsta/nvim-dap-virtual-text and mfussenegger/nvim-dap
require('nvim-dap-virtual-text').setup({
  enabled = true,                     -- enable this plugin (the default)
  enabled_commands = true,            -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
  highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
  highlight_new_as_changed = false,   -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
  show_stop_reason = true,            -- show stop reason when stopped for exceptions
  commented = true,                  -- prefix virtual text with comment string
  -- experimental features:
  virt_text_pos = 'eol',              -- position of virtual text, see `:h nvim_buf_set_extmark()`
  all_frames = false,                 -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
  virt_lines = false,                 -- show virtual lines instead of virtual text (will flicker!)
  virt_text_win_col = nil
}
)
