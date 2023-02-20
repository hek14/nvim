local M = {
  "hrsh7th/nvim-cmp",
  event = {"InsertEnter","CmdlineEnter"},
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lsp-signature-help",
    "lukas-reineke/cmp-rg",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "hrsh7th/cmp-nvim-lua",
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
          sources = cmp.config.sources({
            { name = 'path' }
          }, {
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
}

function M.config()
  local cmp = require"cmp"
  vim.opt.completeopt = "menuone,noselect"

  local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
  end
  local check_back_space = function()
    local col = vim.fn.col '.' - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' ~= nil
  end

  local mine_config_yaml = require("contrib.cmp_config_yaml")
  cmp.register_source("mine_config_yaml", mine_config_yaml.new())

  local disable_cmp_file_types = {"dap-repl"}
  vim.g.cmp_enabled = true
  cmp.setup {
    -- NOTE: guide to toggle cmp completion, now you can add a imap to toggle this option, refer to core/mappings.lua
    enabled = function()
      if vim.tbl_contains(disable_cmp_file_types,vim.bo.filetype) then
        return false
      end

      -- NOTE: this is from https://github.com/hrsh7th/nvim-cmp/blob/93cf84f7deb2bdb640ffbb1d2f8d6d412a7aa558/lua/cmp/config/default.lua
      if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
        return false
      end
      if vim.fn.reg_recording() ~= '' then
        return false
      end
      if vim.fn.reg_executing() ~= '' then
        return false
      end
      -- END

      return vim.g.cmp_enabled
    end,
    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
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
        }

        vim_item.kind = string.format("%s %s", icons[vim_item.kind], vim_item.kind)

        vim_item.menu = ({
          nvim_lsp = "[LSP]",
          nvim_lua = "[Lua]",
          buffer = "[BUF]",
          mine_config_yaml = "[Config]"
        })[entry.source.name]

        return vim_item
      end,
    },
    mapping = {
      ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
      ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
      ["<Up>"] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i' }),
      ['<Down>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i' }),
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.close(),
      ["<CR>"] = cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      },
      ["<tab>"] = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
          -- remove this: separate mappings for luasnip and nvim-cmp
          -- elseif require'luasnip'.expand_or_jumpable() then
          --   vim.fn.feedkeys(t("<Plug>luasnip-expand-or-jump"), "")
        elseif check_back_space() then
          vim.fn.feedkeys(t("<tab>"), "n")
        else
          fallback()
        end
      end,
      ["<S-tab>"] = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
          -- elseif require'luasnip'.jumpable(-1) then
          --   vim.fn.feedkeys(t("<Plug>luasnip-jump-prev"), "")
        else
          fallback()
        end
      end
    },
    sources = {
      { name = "nvim_lsp" },
      { name = 'nvim_lsp_signature_help' },
      -- { name = "mine_config_yaml", trigger_characters = { '.' } }, -- manually trigger
      { name = "luasnip" },
      { name = "buffer" },
      { name = "nvim_lua" },
      { name = "path" },
      { name = "latex_symbols"}
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
  }

  -- Set configuration for specific filetype.
  cmp.setup.filetype('tex', {
    sources = {
      { name = 'omni' },
      { name = 'luasnip' },
      { name = 'buffer' },
    },
  })

  local cmp_rg_complete = function()
    cmp.complete({
      config = {
        sources = {
          { name = "rg" }, -- should install the cmp-rg
        }
      }
    })
  end
  require('core.utils').map('i','<C-g>',cmp_rg_complete,{noremap=true,silent=true})


  local cmp_config = function()
    cmp.complete({
      config = {
        sources = {
          { name = "mine_config_yaml" }, -- should install the cmp-rg
        }
      }
    })
  end
  require('core.utils').map('i','<C-c>',cmp_config,{noremap=true,silent=true})

  vim.cmd('hi! CmpFloatBorder guifg=red')
end
return M
