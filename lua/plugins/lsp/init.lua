-- NOTE: 
-- To learn what capabilities are available you can run the following command in a buffer with a started LSP client:
  -- :lua =vim.lsp.get_active_clients()[1].server_capabilities
-- To top-out one capability: client.server_capabilities.semanticTokensProvider = nil

local au = require('core.autocmds').au
local M = {
  "neovim/nvim-lspconfig",
  event = "BufRead",
  dependencies = {
    "jose-elias-alvarez/null-ls.nvim",
    "j-hui/fidget.nvim",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    {
      'j-hui/fidget.nvim', -- show lsp progress
      config = function() require('fidget').setup {
        text = {
          spinner = 'dots', -- or 'line'
          done = "Done",
          commenced = "Started",
          completed = "Completed",
        },
        window = {
          blend = 0,  -- &winblend for the window
        },
        fmt = {
          stack_upwards = true,  -- list of tasks grows upwards
        }
      } end
    },
    {
      "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
      init = function()
        vim.cmd([[command! -nargs=0 ToggleDiagVirtual lua require'toggle_lsp_diagnostics'.toggle_virtual_text()]])
      end,
    },
  }
}

function M.lsp_hover(_, result, ctx, config)
    local bufnr, winnr = vim.lsp.handlers.hover(_, result, ctx, config)
    print(string.format('bufnr:%s, winnr:%s',bufnr,winnr))
    if bufnr and winnr then
        vim.api.nvim_buf_set_option(bufnr, "filetype", config.filetype)
        return bufnr, winnr
    end
end

function M.lsp_signature_help(_, result, ctx, config)
    local bufnr, winnr = vim.lsp.handlers.signature_help(_, result, ctx, config)

    local current_cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    local ok, window_height = pcall(vim.api.nvim_win_get_height, winnr)

    if not ok then
        return
    end

    if current_cursor_line > window_height + 2 then
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_win_set_config(winnr, {
            anchor = "SW",
            relative = "cursor",
            row = 0,
            col = -1,
        })
    end

    if bufnr and winnr then
        vim.api.nvim_buf_set_option(bufnr, "filetype", config.filetype)
        return bufnr, winnr
    end
end

function M.config()
  local util = require'lspconfig'.util
  local illuminate_present,illuminate = pcall(require,'illuminate')

  local my_lsp_handlers = {
    ["textDocument/hover"] = vim.lsp.with(M.lsp_hover, {
      border = "rounded",
      filetype = "lsp-hover"
    }),
    ["textDocument/signatureHelp"] = vim.lsp.with(M.lsp_signature_help, {
      border = "rounded",
      filetype = "lsp-signature-help"
    }),
  }

  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown", "plaintext" }
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.preselectSupport = true
  capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
  capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
  capabilities.textDocument.completion.completionItem.deprecatedSupport = true
  capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
  capabilities.semanticTokensProvider = true
  capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  }
  -- avoid annoying multiple clients offset_encodings detected warning
  -- refer to: https://github.com/jose-elias-alvarez/null-ls.nvim/issues/428#issuecomment-997226723
  capabilities.offsetEncoding = { "utf-16" }

  local on_attach = function(client, bufnr)
    local launch_in_home = client.config.root_dir == vim.env["HOME"]
    if launch_in_home then
      local answer = vim.fn.input("really want to launch_in_home? y/n: ")
      print('the answer is ',answer)
      if answer == 'n' then
        vim.lsp.buf_detach_client(bufnr,client.id)
        return
      end
    end

    if vim.tbl_contains({"pylance"}, client.name) then
      client.server_capabilities.semanticTokensProvider = {
        legend = {
          tokenTypes = {},
          tokenModifiers = {},
        },
        full = false,
        range = false,
      }
    end
    -- client.server_capabilities.document_formatting = true
    -- client.server_capabilities.document_range_formatting = true
    -- if client.name == "pyright" then
    --   client.server_capabilities.document_formatting = false
    -- end
    -- vim.notify("🐷 catches this buffer!",vim.log.levels.INFO)
    require 'illuminate'.on_attach(client)
    if client.server_capabilities.documentSymbolProvider then
      require("nvim-navic").attach(client, bufnr)
    end
    require("contrib.pig").on_attach(bufnr)
    require('plugins.lsp.keymap').setup(client,bufnr)
    -- NOTE: just use the vv wrapper in .zshrc to do this
    -- if vim.tbl_contains({'pylance','Pylance','pyright','Pyright'},client.name) then
    --   au('ExitPre',{
    --     callback = function()
    --       vim.fn.system(string.format("ps aux | grep -i '%s' | grep -v 'grep' | awk '{print $2}' | xargs -I {} kill -9 {}",client.name))
    --     end,
    --     once = true
    --   })
    -- end
    -- require('contrib.show_diagnostic_in_message').on_attach(bufnr)
  end

  local options = {
    capabilities = capabilities,
    flags = {
      debounce_text_changes = 150
    },
    settings = {},
    on_attach = on_attach,
    handlers = my_lsp_handlers
  }

  local python_lsp = 'pylance'
  local pyright_opts = {
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "off",
          extraPaths = { '.', './*', './**/*', './**/**/*' },
          autoImportCompletions = false,
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly", -- "workspace"
          useLibraryCodeForTypes = true,
          logLevel = "Error",
          diagnosticSeverityOverrides = {
            -- NOTE: refer to https://github.com/microsoft/pyright/blob/main/docs/configuration.md
            reportGeneralTypeIssues = "none",
            reportOptionalMemberAccess = "none",
            reportOptionalSubscript = "none",
            reportPrivateImportUsage = "none",
            reportUnusedImport = "none"
          },
        },
      },
    },
    root_dir = function(fname)
      local root_files = {'pyproject.toml', 'pyrightconfig.json'}
      return util.find_git_ancestor(fname) or
      util.root_pattern(unpack(root_files))(fname) or
      util.path.dirname(fname)
    end
  }
  pyright_opts = vim.tbl_deep_extend('force',options,pyright_opts)

  require("mason-lspconfig").setup({
    automatic_installation = true,
    ensure_installed = {'lua_ls','pyright', 'jsonls'}, -- ruff_lsp not needed, use ruff with null-ls instead
  })

  require("mason-lspconfig").setup_handlers({
    function (server_name) -- the default one
       require("lspconfig")[server_name].setup(options)
    end,
    ["lua_ls"] = function ()
      local opt = {
        settings = {
          single_file_support = true,
          Lua = {
            diagnostics = {
              enable = true,
              globals = { "vim" }
            },
            workspace = {
              checkThirdParty = false
            }
          }
        }
      }
      opt = vim.tbl_deep_extend('force',options,opt)
      require("lspconfig").lua_ls.setup(opt)
    end,
    ["pyright"] = function ()
      if python_lsp == 'pyright' then
        require("lspconfig").pyright.setup(pyright_opts)
      end
    end,
    -- ["ruff_lsp"] = function ()
    --   local opt = {
    --     settings = {
    --       ruff_lsp = {
    --         args = ["--config=/path/to/pyproject.toml"],
    --       }
    --     },
    --     root_dir = function(fname)
    --       local root_files = {'pyproject.toml', 'pyrightconfig.json'}
    --       return util.find_git_ancestor(fname) or
    --       util.root_pattern(unpack(root_files))(fname) or
    --       util.path.dirname(fname)
    --     end
    --   }
    --   require("lspconfig").ruff_lsp.setup(opt)
    -- end,
    ["texlab"] = function ()
      local opt = {
        settings = {
          texlab = {
            build = {
              args = {
                "-xelatex", "-verbose", "-file-line-error",
                "-synctex=1", "-interaction=nonstopmode", "%f"
              },
              executable = "latexmk",
              forwardSearchAfter = true
            },
            chktex = {onOpenAndSave = true},
            forwardSearch = {
              args = {"--synctex-forward", "%l:1:%f", "%p"},
              executable = "zathura"
            }
          }
        }
      }
      opt = vim.tbl_deep_extend('force',options,opt)
      require("lspconfig").texlab.setup(opt)
    end
  })
  if python_lsp == 'pylance' then
    require('plugins.lsp.pylance_config')
    require('lspconfig').pylance.setup(pyright_opts)
  end
  require("plugins.null-ls").setup()
  require("plugins.lsp.diagnostics").setup()
end
return M
