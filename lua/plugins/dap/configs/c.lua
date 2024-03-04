local dap = require('dap')

-- manually start codelldb in tmux, or toggleterm
-- dap.adapters.codelldb = {
--   type = 'server',
--   host = '127.0.0.1',
--   port = 13000
-- }

-- dap.adapters.codelldb = {
--   type = 'server',
--   port = "${port}",
--   executable = {
--     command = vim.fn.stdpath("config") .. "/bin/c/codelldb/adapter/codelldb",
--     args = {"--port", "${port}"},
--   }
-- }
--
-- dap.configurations.cpp = {
--   {
--     name = "Launch file",
--     type = "codelldb",
--     request = "launch",
--     program = function()
--       return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
--     end,
--     cwd = '${workspaceFolder}',
--     stopOnEntry = false,
--   },
-- }

dap.adapters.lldb = {
  type = 'executable',
  command = '/opt/homebrew/opt/llvm/bin/lldb-vscode', -- adjust as needed, must be absolute path
  name = 'lldb'
}

dap.configurations.cpp = {
  {
    name = 'Launch',
    type = 'lldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  },
}

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp
