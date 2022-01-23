local util = require'lspconfig'.util
local trouble_present, trouble = pcall(require, 'trouble')
local M = {}

vim.diagnostic.config {
    virtual_text = false,
    signs = true,
    underline = false,
    signs = true,
    update_in_insert = false
}

function _G.Smart_goto_definition() 
  local bufnr = vim.fn.bufnr()
  vim.cmd [[normal! m`]]
  require('contrib.my_lsp_handler').async_def(
    function ()
      print('using fallback')
      require'nvim-treesitter-refactor.navigation'.goto_definition(bufnr,function ()
        print("dumb goto")
        vim.cmd [[normal! gd]] -- dumb goto definition
      end)
    end
  )
end

function _G.Smart_goto_next_ref(index)
  local bufnr = vim.fn.bufnr()
  vim.cmd [[normal! m`]]
  require('contrib.my_lsp_handler').next_lsp_reference(index,
    function ()
      print('using fallback')
      if index>0 then
        require'nvim-treesitter-refactor.navigation'.goto_next_usage()
      else
        require'nvim-treesitter-refactor.navigation'.goto_previous_usage()
      end
    end)
end

M.setup_lsp = function(attach, capabilities)
    -- require('contrib.my_lsp_handler').setup()
    local lsp_installer = require "nvim-lsp-installer"
    lsp_installer.on_server_ready(function(server)
        local opts = {
            capabilities = capabilities,
            flags = {debounce_text_changes = 150},
            settings = {}
        }

        opts.on_attach = function(client, bufnr)
            print("Lsp catches this buffer!")
            local function buf_set_keymap(...)
                vim.api.nvim_buf_set_keymap(bufnr, ...)
            end

            -- Run nvchad's attach
            -- attach(client, bufnr)
            -- Enable completion triggered by <c-x><c-o>
            vim.api.nvim_buf_set_option(bufnr, "omnifunc",
                                        "v:lua.vim.lsp.omnifunc")

            local map_opts = {noremap = true, silent = true}
            buf_set_keymap("n", "<leader>gd", "<cmd>lua require('telescope.builtin').lsp_definitions()<CR>",
                           map_opts)
            buf_set_keymap("n", "<leader>gr", "<cmd>lua require('telescope.builtin').lsp_references()<CR>",
                           map_opts)
            buf_set_keymap("n", "gd",
                           "<cmd>lua Smart_goto_definition()<CR>",
                           map_opts)
            buf_set_keymap("n", "gr",
                           "<cmd>lua require('contrib.my_lsp_handler').async_ref()<CR>",
                           map_opts)
            buf_set_keymap("n", "gt",
                           "<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>",
                           map_opts)
            buf_set_keymap("n", "<leader>gt",
                           "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>",
                           map_opts)
            buf_set_keymap("n", "<leader>ca",
                           "<cmd>lua require('telescope.builtin').lsp_code_actions()<CR>",
                           map_opts)
            buf_set_keymap("n", "gl",
                           "<cmd>lua vim.diagnostic.open_float()<CR>", map_opts)
            if trouble_present and _G.diagnostic_choice=="Trouble" then
                buf_set_keymap("n", "<leader>D",
                               "<cmd>TroubleToggle document_diagnostics<CR>",
                               map_opts)
            else
                buf_set_keymap("n", "<leader>D",
                               "<cmd>lua require('telescope.builtin').diagnostics({bufnr=0})<CR>",
                               map_opts)
            end
            buf_set_keymap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>",
                           map_opts)
            buf_set_keymap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>",
                           map_opts)
            buf_set_keymap("n", "[r",
                           "<cmd>lua Smart_goto_next_ref(-1)<CR>",
                           map_opts)
            buf_set_keymap("n", "]r",
                           "<cmd>lua Smart_goto_next_ref(1)<CR>",
                           map_opts)
            buf_set_keymap("n", "gs",
                           "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
            buf_set_keymap("n", "<C-k>",
                           "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
            buf_set_keymap("i", "<C-k>",
                           "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
            buf_set_keymap("n", "<leader>rn",
                           "<cmd>lua require('contrib.my_lsp_handler').rename()<CR>", map_opts)
            buf_set_keymap("n", "<leader>wa",
                           "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",
                           map_opts)
            buf_set_keymap("n", "<leader>wr",
                           "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
                           map_opts)
            buf_set_keymap("n", "<leader>wl",
                           "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
                           map_opts)
            buf_set_keymap("n", "K", "N", map_opts)
            buf_set_keymap("n", "E", "<cmd>lua vim.lsp.buf.hover()<CR>",
                           map_opts)
            buf_set_keymap("n", "<leader>fm",
                           "<cmd>lua vim.lsp.buf.formatting()<CR>", map_opts)
        end

        if server.name == "pyright" then
            opts.settings = {
                python = {
                    analysis = {
                        autoImportCompletions = false,
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        useLibraryCodeForTypes = true,
                        logLevel = "Error"
                    }
                }
            }
            opts.root_dir = function(fname)
                local root_files = {'pyproject.toml', 'pyrightconfig.json'}
                return util.find_git_ancestor(fname) or
                           util.root_pattern(unpack(root_files))(fname) or
                           util.path.dirname(fname)
            end
        end

        if server.name == 'texlab' then 
          opts.settings = {
            texlab = {
              build = {
                args = {
                  "-xelatex",
                  "-verbose",
                  "-file-line-error",
                  "-synctex=1",
                  "-interaction=nonstopmode",
                  "%f"
                },
                executable = "latexmk",
                forwardSearchAfter = true
              },
              chktex = {onOpenAndSave = true},
              forwardSearch = {
                args = {
                  "--synctex-forward",
                  "%l:1:%f",
                  "%p"
                },
                executable = "zathura"
              }
            }
          }
        end
        server:setup(opts)
        vim.cmd [[ do User LspAttachBuffers ]]
    end)
end

return M
