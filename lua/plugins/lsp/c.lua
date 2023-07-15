local M = {}
local util = require'lspconfig'.util
M.setup = function(options)
  local root_dir = function(fname)
    local root_files = {'CMakeLists.txt'}
    return util.find_git_ancestor(fname) or
    util.root_pattern(unpack(root_files))(fname) or
    util.path.dirname(fname)
  end
  local opts = {
    on_attach = function(client, bufnr)
      -- client.server_capabilities.document_formatting = false
      -- client.server_capabilities.document_range_formatting = false
      options.on_attach(client, bufnr)
      -- vim.lsp.inlay_hint(bufnr, true)
    end,
    cmd = {
      'clangd',
      '--background-index',
      '--clang-tidy',
      '--header-insertion=iwyu',
    },
    root_dir = root_dir
  }
  opts = vim.tbl_deep_extend('force',options,opts)
  require("lspconfig").clangd.setup(opts)
end
return M
