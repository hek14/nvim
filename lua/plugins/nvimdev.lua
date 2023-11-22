local M = {
  {
    "nvimdev/rapid.nvim",
    enabled = false,
    lazy = false,
    config = function()
      require('rapid').setup()
    end
  },
  {
    "nvimdev/epo.nvim",
    enabled = false,
    event = {"InsertEnter"},
    config = function()
      require('epo').setup({
        -- default value of options.
        fuzzy = true,
        -- increase this value can aviod trigger complete when delete character.
        debounce = 200,
        -- when completion confrim auto show a signature help floating window.
        signature = true,
      })
    end
  },
  {
    'nvimdev/whiskyline.nvim',
    enabled = false,
    dependencies = 'gitsigns.nvim',
    event = 'VimEnter',
    config = function()
      require('whiskyline').setup()
    end
  },
  {
    'nvimdev/indentmini.nvim',
    enabled = false,
    event = 'BufEnter',
    config = function()
      require('indentmini').setup({
        exclude = {'dashboard', 'lazy', 'help', 'markdown', 'terminal', 'floaterm', 'vim'}
      })
    end,
  },
  {
    -- dir = '~/contrib/lspsaga.nvim',
    -- 'hek14/lspsaga.nvim',
    -- branch = 'main',
    'nvimdev/lspsaga.nvim',
    enabled = false,
    event = "BufRead",
    config = function()
      require("lspsaga").setup({
        symbol_in_winbar = { enable = false },
        lightbulb = { enable = false },
        finder = {
          keys = {
            jump_to = 'p',
            edit = { 'o', '<CR>' },
            vsplit = 's',
            split = 'i',
            tabe = 't',
            tabnew = 'r',
            quit = { 'q', '<ESC>' },
            close_in_preview = '<C-q>'
          },
        },
      })
      local au = require('core.autocmds').au
      au('FileType', {
        callback = function ()
          vim.defer_fn(function ()
            vim.keymap.set('n','e','k',{noremap=true,nowait=true,silent=true,buffer=true})
          end,5)
        end,
        pattern = 'lspsagafinder'
      })
    end,
    dependencies = {
      {"nvim-tree/nvim-web-devicons"},
      {"nvim-treesitter/nvim-treesitter"}
    }
  }
}

return M
