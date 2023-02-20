-- NOTE: 
-- To learn what capabilities are available you can run the following command in a buffer with a started LSP client:
  -- :lua =vim.lsp.get_active_clients()[1].server_capabilities
-- To top-out one capability: client.server_capabilities.semanticTokensProvider = nil


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
      "ray-x/lsp_signature.nvim",
      enabled = false,
      config = function ()
        local default = {
          bind = true,
          doc_lines = 0,
          floating_window = true,
          fix_pos = true,
          hint_enabled = true,
          hint_prefix = " ",
          hint_scheme = "String",
          hi_parameter = "Search",
          max_height = 22,
          max_width = 120, -- max_width of signature floating_window, line will be wrapped if exceed max_width
          handler_opts = {
            border = "single", -- double, single, shadow, none
          },
          zindex = 200, -- by default it will be on top of all floating windows, set to 50 send it to bottom
          padding = "", -- character to pad on left and right of signature can be ' ', or '|'  etc
        }
        require("lspsignature").setup(default)
      end
    },
    {
      "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
      init = function()
        vim.cmd([[command! -nargs=0 ToggleDiagVirtual lua require'toggle_lsp_diagnostics'.toggle_virtual_text()]])
      end,
    },
  }
}


function M.config()
  local util = require'lspconfig'.util
  local python_lsp = 'pyright'

  local illuminate_present,illuminate = pcall(require,'illuminate')
  vim.cmd([[
  autocmd ColorScheme * |
  " hi def link LspReferenceText CursorLine |
  " hi def link LspReferenceWrite CursorLine |
  " hi def link LspReferenceRead CursorLine
  " hi default LspReferenceRead cterm=bold gui=Bold ctermbg=yellow guifg=yellow guibg=purple4 |
  " hi default LspReferenceText cterm=bold gui=Bold ctermbg=red guifg=SlateBlue guibg=MidnightBlue |
  " hi default LspReferenceWrite cterm=bold gui=Bold,Italic ctermbg=red guifg=DarkSlateBlue guibg=MistyRose
  hi default LspReferenceRead ctermbg=237 guibg=#343d46
  hi default LspReferenceText ctermbg=237 guibg=#343d46
  hi default LspReferenceWrite ctermbg=237 guibg=#343d46
  hi clear CursorLine
  ]])


  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "single",
  })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = "single",
  })


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
    -- if vim.tbl_contains({"pyright", "lua_ls"}, client.name) then
    --   client.server_capabilities.document_formatting = false
    -- end
    -- client.server_capabilities.document_formatting = true
    -- client.server_capabilities.document_range_formatting = true
    -- if client.name == "pyright" then
    --   client.server_capabilities.document_formatting = false
    -- end
    vim.notify("🐷 catches this buffer!",vim.log.levels.INFO)
    require 'illuminate'.on_attach(client)
    if client.server_capabilities.documentSymbolProvider then
      require("nvim-navic").attach(client, bufnr)
    end
    require("contrib.pig").on_attach(bufnr)
    require('contrib.my_document_highlight').on_attach(bufnr)
    require('plugins.lsp.keymap').setup(client,bufnr)
    -- require('contrib.show_diagnostic_in_message').on_attach(bufnr)
  end

  local options = {
    capabilities = capabilities,
    flags = {
      debounce_text_changes = 150
    },
    settings = {},
    on_attach = on_attach,
  }


  require("mason").setup()
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
            }
          }
        }
      }
      opt = vim.tbl_deep_extend('force',options,opt)
      require("lspconfig").lua_ls.setup(opt)
    end,
    ["pyright"] = function ()
      if python_lsp == 'pyright' then
        local opt = {
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
        opt = vim.tbl_deep_extend('force',options,opt)
        require("lspconfig").pyright.setup(opt)
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
    require('lspconfig.configs').pylance = require('plugins.lsp.pylance_expand')
    local pylance_config = require('plugins.lsp.pylance_config')
    pylance_config = vim.tbl_deep_extend('force',options,pylance_config)
    require('lspconfig').pylance.setup(pylance_config)
  end
  require("plugins.null-ls").setup()
  require("plugins.lsp.diagnostics").setup()
end
return M
