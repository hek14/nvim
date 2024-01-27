local M = {
  {
    "hrsh7th/nvim-cmp",
    event = {"InsertEnter","CmdlineEnter"},
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      -- "lukas-reineke/cmp-rg",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "rafamadriz/friendly-snippets",
      {
        "hrsh7th/cmp-cmdline",
        config = function()
          local cmp = require("cmp")
          -- `/` cmdline setup.
          cmp.setup.cmdline('/', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = 'buffer' }
            }
          })
          -- `:` cmdline setup.
          cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources(
            { name = 'path' },
            {
              {
                name = 'cmdline',
                option = {
                  ignore_cmds = { 'Man', '!' }
                }
              }
            })
          })
        end,
      }, -- enhance grep and quickfix list
    },
  },
  {
    'kdheepak/cmp-latex-symbols',
    dependencies = 'hrsh7th/nvim-cmp',
    ft = 'tex'
  }
}

local function before_words()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return line:sub(0, col)
end

local function feedkeys(key, mode)
  local keycode = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keycode, mode, false)
end

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end
local check_back_space = function()
  local col = vim.fn.col '.' - 1
  return col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' ~= nil
end

M[1].init = function()
  -- toggle cmp
  vim.g.cmp_enabled = true
  vim.api.nvim_create_user_command('ToggleCmp',function()
    if vim.g.cmp_enabled then
      require("cmp").close()
      vim.g.cmp_enabled = false
    else
      require('cmp').complete()
      vim.g.cmp_enabled = true
    end
  end,{})

  require('core.utils').map("i", "<C-q>","<Cmd>ToggleCmp<CR>")
end

M[1].config = function()
  local cmp = require('cmp')
  cmp.setup{
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    sources = {
      { name = 'nvim_lua' },
      { name = "luasnip" },
      { name = "path" },
      { name = "remote_path" },
      { name = "nvim_lsp" },
      { name = 'nvim_lsp_signature_help' },
      {
        name = 'buffer',
        -- keyword_length = 5,
        option = {
          get_bufnrs = function()
            local win_bufs = require('core.utils').get_all_window_buffer_filetype()
            local bufs = {}
            for i, win_buf in ipairs(win_bufs) do
              table.insert(bufs, win_buf.bufnr)
            end
            return bufs
          end
        }
      }
    },
    enabled = function()
      local ft = vim.api.nvim_buf_get_option(0,'ft')
      if string.match(ft, 'Prompt') then
        return false
      end
      return vim.g.cmp_enabled
    end,
    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },
    mapping = {
      ["<C-a>"] = cmp.mapping.close(), -- or abort
      ['<CR>'] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      }),
      -- ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
      -- ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
      -- ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      -- ["<C-f>"] = cmp.mapping.scroll_docs(4),
    }
  }
  vim.cmd('hi! CmpFloatBorder guifg=red')

  require('core.utils').map("i","<C-n>",function()
    if(cmp.visible()) then
      cmp.select_next_item { behavior = cmp.SelectBehavior.Insert }
    else
      feedkeys('<C-o>o','n')
    end
  end)

  require('core.utils').map("i","<C-p>",function()
    if(cmp.visible()) then
      cmp.select_prev_item { behavior = cmp.SelectBehavior.Insert }
    else
      feedkeys('<C-o>O','n')
    end
  end)

  local mine_config_yaml = require("contrib.cmp_config_yaml")
  cmp.register_source("mine_config_yaml", mine_config_yaml.new())
  cmp.register_source('remote_path', require('contrib.parse_remote_path').new())

  local cmp_config = function()
    cmp.complete({
      config = {
        sources = {
          { name = "mine_config_yaml" }, -- should install the cmp-rg
        }
      }
    })
  end
  vim.keymap.set('i','<C-c>',cmp_config,{noremap=true,silent=true})
end

return M
