local M = {}
local util = require("lspconfig.util")
M.setup = function(options)
  local capabilities = options.capabilities
  -- capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
  local opts = {
    cmd = {vim.fn.expand("~/.config/nvim/bin/markdown/markdown-oxide/target/release/markdown-oxide")},
    capabilities = capabilities,
    root_dir = util.root_pattern('.git', vim.fn.getcwd()), -- this is a temp fix for an error in the lspconfig for this LS
  }
  opts = vim.tbl_deep_extend('force',options,opts)
  require("lspconfig").markdown_oxide.setup(opts)
end
return M
