local M = {}
require('core.utils').append_env_path(vim.fn.stdpath('config') .. '/bin/lua/bin')
M.setup = function(options)
  local opts = {
    on_attach = function(client, bufnr)
      client.server_capabilities.semanticTokensProvider = nil
      client.server_capabilities.document_formatting = false
      client.server_capabilities.document_range_formatting = false
      options.on_attach(client, bufnr)
    end,
    settings = {
      single_file_support = true,
      Lua = {
        diagnostics = {
          enable = true,
          globals = { "vim" }
        },
        workspace = {
          library = {
            vim.env.VIMRUNTIME,
            vim.env.HOME .. '/.local/share/nvim/lazy/emmylua-nvim',
            -- vim.api.nvim_get_runtime_file('', true),
          },
          checkThirdParty = false
        }
      }
    }
  }
  opts = vim.tbl_deep_extend('force',options,opts)
  require("lspconfig").lua_ls.setup(opts)
end
return M
