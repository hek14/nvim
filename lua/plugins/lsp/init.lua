-- NOTE: 
-- To learn what capabilities are available you can run the following command in a buffer with a started LSP client:
-- :lua =vim.lsp.get_active_clients()[1].server_capabilities
-- To top-out one capability: client.server_capabilities.semanticTokensProvider = nil

local au = require('core.autocmds').au
local map = require('core.utils').map
local M = {
  "neovim/nvim-lspconfig",
  cmd = 'LspStart',
  init = function ()
    local group = vim.api.nvim_create_augroup('load_lsp',{clear=true})
    vim.api.nvim_create_autocmd('BufRead', { callback = function ()
      if package.loaded['lspconfig'] then
        vim.schedule(function ()
          vim.api.nvim_clear_autocmds({group='load_lsp'})
        end)
      end
      local bufnr = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_line_count(bufnr) <= 3000 and not package.loaded['lspconfig'] then
        require('lspconfig')
        vim.schedule(function ()
          vim.cmd[[LspStart]]
          vim.api.nvim_clear_autocmds({group='load_lsp'})
        end)
      end
    end,
    group = group
  })
  end,
  dependencies = {
    {
      'simrat39/symbols-outline.nvim',
      cmd = { 'SymbolsOutline' },
      config = function()
        local opts = {
          keymaps = {
            fold = 'f',
            unfold = 'F',
          },
        }
        require('symbols-outline').setup(opts)
        map("n","<leader>ls",":SymbolsOutline<CR>")
      end,
    },
    {
      'folke/trouble.nvim',
      config = function()
        require('trouble').setup({})
      end,
    },
    {
      "SmiteshP/nvim-navic",
      config = function()
        map('n','[g',function()
          local buf = vim.api.nvim_get_current_buf()
          local data = require('nvim-navic').get_data(buf)
          if #data == 0 then return end
          vim.cmd [[normal! m`]]
          local last = data[#data]
          local curr = vim.api.nvim_win_get_cursor(0)
          if curr[1]==last.scope.start.line then
            if #data -1 > 0 then
              vim.api.nvim_win_set_cursor(0,{data[#data-1].scope.start.line, data[#data-1].scope.start.character})
            end
          else
            if #data > 0 then
              vim.api.nvim_win_set_cursor(0,{data[#data].scope.start.line, data[#data].scope.start.character})
            end
          end
          if #vim.fn.matchstr(vim.fn.expand('<cword>'), [[\(def\|class\|function\|struct\)]])>0 then
            vim.cmd('normal! w')
          end
        end)
      end
    },
    {
      "SmiteshP/nvim-navbuddy",
      dependencies = {
        "SmiteshP/nvim-navic",
        "MunifTanjim/nui.nvim"
      },
      event = 'BufRead',
      config = function()
        local navbuddy = require("nvim-navbuddy")
        local actions = require("nvim-navbuddy.actions")
        navbuddy.setup {
          mappings = {
            ["n"] = actions.next_sibling(),     -- down
            ["e"] = actions.previous_sibling(), -- up
            ["h"] = actions.parent(),           -- Move to left panel
            ["i"] = actions.children(),         -- Move to right panel
            ["N"] = actions.move_down(),        -- Move focused node down
            ["E"] = actions.move_up(),          -- Move focused node up
            ["u"] = actions.insert_name(),      -- Insert at start of name
            ["U"] = actions.insert_scope(),     -- Insert at start of scope
          },
          lsp = {
            auto_attach = true
          },
        }
      end
    },
    {
      'RRethy/vim-illuminate',
      event = 'BufRead',
      enabled = true,
      config = function()
        require('illuminate').configure({
          -- providers: provider used to get references in the buffer, ordered by priority
          providers = {
            'lsp',
            'treesitter',
            -- 'regex',
          },
          delay = 200
        })
      end
    },
    {
      "utilyre/barbecue.nvim", -- NOTE: for this to work well, should use SFMono Nerd Font for terminal
      enabled = false,
      dependencies = { 'SmiteshP/nvim-navic','nvim-tree/nvim-web-devicons' },
      config = function()
        require("barbecue").setup()
      end
    },
    { 
      'Bekaboo/dropbar.nvim',
      enabled = false,
    },
    {
      'hek14/symbol-overlay.nvim',
      config = function ()
        require('symbol-overlay').setup()
        require'telescope'.load_extension('symbol_overlay')
      end
    },
    {
      'ii14/emmylua-nvim',
      ft = 'lua',
    }
  }
}

function M.lsp_hover(_, result, ctx, config)
    local bufnr, winnr = vim.lsp.handlers.hover(_, result, ctx, config)
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
  -- avoid annoying multiple clients offset_encodings detected warning
  -- refer to: https://github.com/jose-elias-alvarez/null-ls.nvim/issues/428#issuecomment-997226723
  capabilities.offsetEncoding = { "utf-16" }

  local on_attach = function(client, bufnr)
    -- vim.schedule(function()
      -- vim.notify(string.format("🐷 %s catches buffer %s!",client.name,bufnr),vim.log.levels.INFO)
    -- end)
    local illuminate_present,illuminate = pcall(require,'illuminate')
    if illuminate_present then
      require 'illuminate'.on_attach(client)
    end

    local navic_present,navic = pcall(require,'nvim-navic')
    if client.server_capabilities.documentSymbolProvider and navic_present then
      require("nvim-navic").attach(client, bufnr)
    end
    require('plugins.lsp.keymap').setup(client,bufnr)
    -- require("contrib.pig").on_attach(bufnr)
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
  require('plugins.lsp.lua').setup(options)
  require('plugins.lsp.c').setup(options)
  require('plugins.lsp.latex').setup(options)
  -- NOTE: python: currently use jedi for navigation and ruff for diagnostics
  -- require('plugins.lsp.python').setup(options,'jedi_language_server')
  -- require('plugins.lsp.python').setup(options,'ruff_lsp')
  -- require('plugins.lsp.python').setup(options,'diagnosticls')
  -- require('plugins.lsp.python').setup(options,'anakin_language_server')
  require('plugins.lsp.python').setup(options,'pylance')
  -- require('plugins.lsp.python').setup(options,'pyright')
  -- require('plugins.lsp.python').setup(options,'pylyzer')
  require("plugins.lsp.diagnostics").setup()
end
return M
