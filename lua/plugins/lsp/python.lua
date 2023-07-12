local M = {}
require('core.utils').append_env_path(vim.fn.stdpath('config') .. '/bin/python') -- pyright, pylance
local util = require'lspconfig'.util
local root_dir = function(fname)
  local root_files = {'pyproject.toml', 'pyrightconfig.json', '.root', '.python-version', '.envrc', '.vscode'}
  return util.find_git_ancestor(fname) or
  util.root_pattern(unpack(root_files))(fname) or
  util.path.dirname(fname)
end
M.setup = function(options,server)
  local opts = {}
  if vim.tbl_contains({'pylance','pyright'}, server)then
    if server == 'pylance' then
      require('plugins.lsp.pylance_config')
    end
    opts =  {
      on_attach = function(client, bufnr)
        if client.name == 'pylance' then
          client.server_capabilities.semanticTokensProvider = nil
        end
        options.on_attach(client,bufnr)
        -- vim.lsp.inlay_hint(bufnr,true)
        local launch_in_home = client.config.root_dir == vim.env["HOME"]
        if launch_in_home then
          local answer = vim.fn.input("really want to launch_in_home? y/n: ")
          if answer == 'n' then
            vim.lsp.buf_detach_client(bufnr,client.id)
            return
          end
        end
      end,
      settings = {
        python = {
          analysis = {
            -- NOTE: refer to https://github.com/microsoft/pyright/blob/main/docs/configuration.md
            -- NOTE: and https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance
            -- inlayHints= {
            --   enable = true,
            --   functionReturnTypes = true,
            --   variableTypes = true,
            -- },
            -- extraPaths = { '.', './*', './**/*', './**/**/*' },
            -- include = {},
            -- exclude = {},
            typeCheckingMode = "off",
            autoImportCompletions = false,
            autoSearchPaths = false,
            diagnosticMode = "openFilesOnly", -- or "workspace"
            useLibraryCodeForTypes = true,
            -- logLevel = "Error",
            diagnosticSeverityOverrides = {
              -- reportGeneralTypeIssues = "none",
              -- reportOptionalMemberAccess = "none",
              -- reportOptionalSubscript = "none",
              -- reportPrivateImportUsage = "none",
              -- reportUnboundVariable = "none",
              -- reportUnusedImport = "none",
              -- reportUnusedClass = "none",
              -- reportUnusedFunction = "none",
              -- reportUnusedVariable = "none",
            },
          },
        },
      },
      root_dir = root_dir
    }
  elseif server == 'pylsp' then
    opts = {
      settings = {
        pylsp = {
          plugins = {
            pycodestyle = {
              ignore = {'W391'},
              maxLineLength = 100
            }
          }
        }
      }
    }
  elseif server == 'ruff_lsp' then
    opts = {
      -- settings = {
        --   ruff_lsp = {
          --     args = {"--config=/path/to/pyproject.toml"},
          --   }
          -- },
          root_dir = root_dir
        }
  elseif server == 'coc-pyright' then
    print('setting up coc-pyrht')
    opts = {
      cmd = {
        'node',
        '--max-old-space-size=3072',
        vim.fn.expand('~/.config/coc/extensions/node_modules/coc-pyright/node_modules/pyright/langserver.index.js'),
        '--stdio'
      },
      root_dir = root_dir,
    }
    server = 'pyright' -- pyright is a valid item in lspconfig
  else
    opts = {
      root_dir = root_dir
    }
  end
  opts = vim.tbl_deep_extend('force',options, opts)
  require("lspconfig")[server].setup(opts)
end
return M
