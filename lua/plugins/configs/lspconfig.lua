local util = require'lspconfig'.util
local trouble_present, trouble = pcall(require, 'trouble')

local M = {}
require("plugins.configs.others").lsp_handlers()

function M.Smart_goto_definition()
  local bufnr = vim.fn.bufnr()
  vim.cmd [[normal! m`]]
  require('contrib.my_lsp_handler').async_def(function()
    print('using fallback')
    require'nvim-treesitter-refactor.navigation'.goto_definition(bufnr,
      function()
        print("dumb goto")
        vim.cmd [[normal! gd]] -- dumb goto definition
      end)
  end)
end

function M.Smart_goto_next_ref(index)
  local bufnr = vim.fn.bufnr()
  vim.cmd [[normal! m`]]
  require('contrib.my_lsp_handler').next_lsp_reference(index, function()
    print('using fallback')
    if index > 0 then
      require'nvim-treesitter-refactor.navigation'.goto_next_usage()
    else
      require'nvim-treesitter-refactor.navigation'.goto_previous_usage()
    end
  end)
end

-- NOTE: refer to https://github.com/lucasvianav/nvim
function M.show_documentation()
  if vim.tbl_contains({ 'vim', 'help', 'lua' }, vim.o.filetype) then
    local has_docs = pcall(vim.api.nvim_command, 'help ' .. vim.fn.expand('<cword>'))

    if not has_docs then
      vim.lsp.buf.hover()
    end
  else
    vim.lsp.buf.hover()
  end
end

local are_diagnostics_visible = true
---Toggle vim.diagnostics (visibility only).
function M.toggle_diagnostics_visibility()
  if are_diagnostics_visible then
    vim.diagnostic.hide()
    are_diagnostics_visible = false
  else
    vim.diagnostic.show()
    are_diagnostics_visible = true
  end
end

function M.on_attach(client, bufnr)
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  client.resolved_capabilities.document_formatting = false
  client.resolved_capabilities.document_range_formatting = false
  -- Enable completion triggered by <c-x><c-o>
  buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

  require("core.mappings").lspconfig()
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown", "plaintext" }
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.preselectSupport = true
capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
capabilities.textDocument.completion.completionItem.deprecatedSupport = true
capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    "documentation",
    "detail",
    "additionalTextEdits",
  },
}

local lsp_installer = require "nvim-lsp-installer"
local root_dir = require"nvim-lsp-installer.settings".current.install_root_dir
lsp_installer.on_server_ready(function(server)
  local opts = {
    capabilities = capabilities,
    flags = {debounce_text_changes = 150},
    settings = {}
  }

  opts.on_attach = function(client, bufnr)
    print("Lsp catches this buffer!")
    local ok,illuminate = pcall(require,'illuminate')
    if ok then
      require 'illuminate'.on_attach(client)
    end

    local function buf_set_keymap(...)
      vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, "omnifunc",
      "v:lua.vim.lsp.omnifunc")

    local map_opts = {noremap = true, silent = true}
    buf_set_keymap("n", "<leader>gd",
      "<cmd>lua require('telescope.builtin').lsp_definitions()<CR>",
      map_opts)
    buf_set_keymap("n", "<leader>gr",
      "<cmd>lua require('telescope.builtin').lsp_references()<CR>",
      map_opts)
    buf_set_keymap("n", "gd", "<cmd>lua require('plugins.configs.lspconfig').Smart_goto_definition()<CR>",
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
    if trouble_present and _G.diagnostic_choice == "Trouble" then
      buf_set_keymap("n", "<leader>D",
        "<cmd>TroubleToggle document_diagnostics<CR>",
        map_opts)
    else
      buf_set_keymap("n", "<leader>D",
        "<cmd>lua require('telescope.builtin').diagnostics({bufnr=0})<CR>",
        map_opts)
    end
    buf_set_keymap("n", "<leader>,", "<cmd>lua vim.lsp.buf.document_highlight()<CR>",map_opts)
    buf_set_keymap("n", "<leader>.", "<cmd>lua vim.lsp.buf.clear_references()<CR>",map_opts)
    buf_set_keymap("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>",
      map_opts)
    buf_set_keymap("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>",
      map_opts)
    -- buf_set_keymap("n", "[r", "<cmd>lua require('plugins.configs.lspconfig').Smart_goto_next_ref(-1)<CR>",
    --                map_opts)
    -- buf_set_keymap("n", "]r", "<cmd>lua require('plugins.configs.lspconfig').Smart_goto_next_ref(1)<CR>",
    --                map_opts)
    buf_set_keymap('n', ']r', '<cmd>lua require"illuminate".next_reference{wrap=true}<cr>', {noremap=true})
    buf_set_keymap('n', '[r', '<cmd>lua require"illuminate".next_reference{reverse=true,wrap=true}<cr>', {noremap=true})

    buf_set_keymap("n", "gs",
      "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
    buf_set_keymap("n", "<C-k>",
      "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
    -- buf_set_keymap("i", "<C-k>",
    --                "<cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
    buf_set_keymap("n", "<leader>rn",
      "<cmd>lua require('contrib.my_lsp_handler').rename()<CR>",
      map_opts)
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
    buf_set_keymap("n", "E", "<cmd>lua require('plugins.configs.lspconfig').show_documentation()<CR>",
      map_opts)
    buf_set_keymap("n", "<leader>fm",
      "<cmd>lua vim.lsp.buf.formatting()<CR>", map_opts)
    buf_set_keymap("n", "<leader>[r",
      "<cmd>lua require'nvim-treesitter-refactor.navigation'.goto_previous_usage()<CR>",
      map_opts)
    buf_set_keymap("n", "<leader>]r",
      "<cmd>lua require'nvim-treesitter-refactor.navigation'.goto_next_usage()<CR>",
      map_opts)
    buf_set_keymap('n', 'gi',
      "<cmd>lua vim.lsp.buf.incoming_calls()<CR>",
      map_opts
    )
    buf_set_keymap('n', 'go',
      "<cmd>lua vim.lsp.buf.outgoing_calls()<CR>",
      map_opts
    )
    require('contrib.my_document_highlight').on_attach(bufnr)
    if vim.tbl_contains({"pyright", "sumneko_lua"}, client.name) then
      client.resolved_capabilities.document_formatting = false
    end
  end

  if server.name == "pyright" then
    opts.settings = {
      python = {
        analysis = {
          extraPaths = { '.', './*', './**/*', './**/**/*' },
          useImportHeuristic = true,
          autoImportCompletions = false,
          autoSearchPaths = true,
          diagnosticMode = "workspace",
          useLibraryCodeForTypes = true,
          logLevel = "Error",
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
  end
  if server.name == "sumneko_lua" then
    local luadev = require("lua-dev").setup({
      -- add any options here, or leave empty to use the default settings
      lspconfig = {
        cmd = {root_dir .. "/sumneko_lua/extension/server/bin/lua-language-server"},
        on_attach = opts.on_attach,
        settings = {
          Lua = {
            workspace = {
              checkThirdParty = false, -- THIS IS THE IMPORTANT LINE TO ADD: avoid the annoying "OpenResty"
            },
          }
        }
      },
    })
    require('lspconfig').sumneko_lua.setup(luadev)
  else
    server:setup(opts)
  end
  vim.cmd [[ do User LspAttachBuffers ]]
end)
return M
