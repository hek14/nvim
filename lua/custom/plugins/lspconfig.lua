local util = require'lspconfig'.util
local M = {}

M.setup_lsp = function(attach, capabilities)
   local lsp_installer = require "nvim-lsp-installer"

   lsp_installer.on_server_ready(function(server)
      local opts = {
         on_attach = attach,
         capabilities = capabilities,
         flags = {
            debounce_text_changes = 150,
         },
         settings = {},
      }

      opts.on_attach = function(client, bufnr)
        local function buf_set_keymap(...)
          vim.api.nvim_buf_set_keymap(bufnr, ...)
        end

        -- Run nvchad's attach
        attach(client, bufnr)

        -- Use nvim-code-action-menu for code actions for rust
        local map_opts = { noremap = true, silent = true }
        vim.api.nvim_buf_del_keymap(bufnr,"n","ge")
        buf_set_keymap("n", "gl", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", map_opts)
        buf_set_keymap("n", "gt", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", map_opts)
        buf_set_keymap("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
        buf_set_keymap("n", "K", "N", map_opts)
        buf_set_keymap("n", "E", "<cmd>lua vim.lsp.buf.hover()<CR>", map_opts)
      end


      if server.name == "pyright" then
        opts.settings = {
          python = {
            analysis = {
              autoImportCompletions = false,
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
              logLevel = "Error",
            }
          }
        }
        opts.root_dir = function(fname)
          local root_files = {
            'pyproject.toml',
            'pyrightconfig.json',
          }
          return util.find_git_ancestor(fname) or util.root_pattern(unpack(root_files))(fname) or util.path.dirname(fname)
        end
      end

      server:setup(opts)
      vim.cmd [[ do User LspAttachBuffers ]]
   end)
end

return M
