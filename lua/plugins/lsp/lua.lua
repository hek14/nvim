local M = {}
require('core.utils').append_env_path(vim.fn.stdpath('config') .. '/bin/lua/bin')
M.setup = function(options)
  local opts = {
    on_attach = function(client, bufnr)
      client.server_capabilities.document_formatting = false
      client.server_capabilities.document_range_formatting = false
      options.on_attach(client, bufnr)
      -- vim.lsp.inlay_hint.enable(bufnr,true)
    end,
    settings = {
      single_file_support = true,
      Lua = {
        -- hint = {
        --   enable = true,
        --   arrayIndex = 'enable',
        --   setType = true
        -- },
        -- Version of Lua you're targeting, change as necessary
        runtime = {
          version = 'Lua 5.1',
        },
        diagnostics = {
          enable = true,
          globals = { "vim" },
          -- disable = { "missing-fields", "Deprecated" }
        },
        workspace = {
          library = {
            vim.env.VIMRUNTIME,
            '${3rd}/luv/library',
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
