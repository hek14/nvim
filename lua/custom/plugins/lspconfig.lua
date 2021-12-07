local util = require'lspconfig'.util
local telescope_present,telescope = pcall(require,'telescope')
local trouble_present,trouble = pcall(require,'trouble')
local M = {}

M.setup_lsp = function(attach, capabilities)
   local lsp_installer = require "nvim-lsp-installer"

   if telescope_present then
     vim.lsp.handlers["textDocument/references"] = require("telescope.builtin").lsp_references
     vim.lsp.handlers['textDocument/codeAction'] = require("telescope.builtin").lsp_code_actions
     vim.lsp.handlers['textDocument/definition'] = require("telescope.builtin").lsp_definitions
     vim.lsp.handlers['textDocument/typeDefinition'] = require("telescope.builtin").lsp_type_definitions
     vim.lsp.handlers['textDocument/implementation'] = require("telescope.builtin").lsp_implementations
     vim.lsp.handlers['textDocument/documentSymbol'] = require("telescope.builtin").lsp_document_symbols
   end

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
        print("Lsp catches this buffer!")
        local function buf_set_keymap(...)
          vim.api.nvim_buf_set_keymap(bufnr, ...)
        end

        -- Run nvchad's attach
        -- attach(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr,"omnifunc", "v:lua.vim.lsp.omnifunc")

        local map_opts = { noremap = true, silent = true }
        buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", map_opts)
        buf_set_keymap("n", "gl", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", map_opts)
        if trouble_present then
          buf_set_keymap("n", "<leader>D", "<cmd>TroubleToggle lsp_document_diagnostics<CR>", map_opts)
        end
        buf_set_keymap("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", map_opts)
        buf_set_keymap("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", map_opts)
        buf_set_keymap("n", "gt", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", map_opts)
        buf_set_keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", map_opts)
        buf_set_keymap("n", "<leader>gt", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>", map_opts)
        buf_set_keymap("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
        buf_set_keymap("i", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
        buf_set_keymap("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", map_opts)
        buf_set_keymap("n", "<leader>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", map_opts)
        buf_set_keymap("n", "<leader>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", map_opts)
        buf_set_keymap("n", "<leader>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", map_opts)
        buf_set_keymap("n", "K", "N", map_opts)
        buf_set_keymap("n", "E", "<cmd>lua vim.lsp.buf.hover()<CR>", map_opts)
        buf_set_keymap("n", "<leader>fm", "<cmd>lua vim.lsp.buf.formatting()<CR>", map_opts)
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