require('dap-python').setup(vim.fn.exepath('python'),{console = 'internalConsole'})

-- local dap = require('dap')
-- dap.adapters.python = {
--   type = 'executable',
--   command = os.getenv('HOME') .. '/miniconda3/bin/python',
--   args = { '-m', 'debugpy.adapter' },
-- }
--
-- dap.configurations.python = {
--   {
--     type = 'python',
--     request = 'launch',
--     name = "Launch file",
--     program = "${file}",
--     pythonPath = function()
--       return vim.fn.exepath('python')
--     end,
--   },
-- }
