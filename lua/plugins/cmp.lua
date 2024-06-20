local M = {
  {
    "hrsh7th/nvim-cmp",
    event = {"InsertEnter","CmdlineEnter"},
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-omni",
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
    performance = {
      debounce = 30,
      throttle = 15,
      fetching_timeout = 250,
      confirm_resolve_timeout = 40,
      async_budget = 0.5,
      max_view_entries = 100,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    sources = {
      { name = 'nvim_lua', priority = 1000 },
      { name = "luasnip", priority = 750 },
      { name = "path", priority = 250 },
      -- { name = "remote_path", priority = 100 },
      { name = "nvim_lsp", priority = 1000 },
      { name = 'nvim_lsp_signature_help' },
      {
        name = 'buffer',
        priority = 500,
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
    -- NOTE: according to TJ DeVries, the good principle for keymaps is: One key always does one thing. 
    mapping = cmp.mapping.preset.insert {
      ["<C-a>"] = cmp.mapping.close(), -- or abort
      ['<C-y>'] = cmp.mapping(
        cmp.mapping.confirm({ -- NOTE:<C-y> is the default mapping for accepting completion
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        },
        {"i", "c"}
      )),
      ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
      ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
    },
    formatting = {
      format = function(entry, vim_item)
        local icons = {
          Text = "",
          Method = "",
          Function = "",
          Constructor = "",
          Field = "ﰠ",
          Variable = "",
          Class = "ﴯ",
          Interface = "",
          Module = "",
          Property = "ﰠ",
          Unit = "塞",
          Value = "",
          Enum = "",
          Keyword = "",
          Snippet = "",
          Color = "",
          File = "",
          Reference = "",
          Folder = "",
          EnumMember = "",
          Constant = "",
          Struct = "פּ",
          Event = "",
          Operator = "",
          TypeParameter = "",
          Omni = "⚾️"
        }
        if(entry.source.name == "omni") then
          vim_item.kind = "Omni"
        end
        vim_item.kind = string.format("%s %s", icons[vim_item.kind], vim_item.kind)
        vim_item.menu = ({
          omni = "[Omni]",
          nvim_lsp = "[Lsp]",
          nvim_lua = "[Lua]",
          buffer = "[Buf]",
          mine_config_yaml = "[Config]"
        })[entry.source.name]
        return vim_item
      end,
    },
  }
  vim.cmd('hi! CmpFloatBorder guifg=red')
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
  cmp.setup.filetype({ 'tex' }, {
    sources = {
      { name = 'omni', option = { disable_omnifuncs = { 'v:lua.vim.lsp.omnifunc' } } },
      { name = "luasnip" },
      { name = "path" },
      { name = "nvim_lsp" },
      {
        name = 'buffer',
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
  })
  cmp.setup.filetype({ 'markdown' }, {
    sources = {
      -- NOTE:https://github.com/Feel-ix-343/markdown-oxide?tab=readme-ov-file#neovim
      {
        name = 'nvim_lsp',
        option = {
          markdown_oxide = {
            keyword_pattern = [[\(\k\| \|\/\|#\)\+]]
          }
        }
      },
      { name = "luasnip" },
      { name = "path" },
      {
        name = 'buffer',
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
  })

end

return M
