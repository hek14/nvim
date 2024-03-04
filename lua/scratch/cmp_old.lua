local M = {
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
    'kdheepak/cmp-latex-symbols',
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

function M.config()
  local cmp = require"cmp"
  vim.opt.completeopt = { "menu", "menuone", "noselect" }

  local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
  end
  local check_back_space = function()
    local col = vim.fn.col '.' - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' ~= nil
  end

  local mine_config_yaml = require("contrib.cmp_config_yaml")
  cmp.register_source("mine_config_yaml", mine_config_yaml.new())

  vim.g.cmp_enabled = true
  cmp.setup {
    completion = {
      autocomplete = false
    },
    -- NOTE: guide to toggle cmp completion, now you can add a imap to toggle this option, refer to core/mappings.lua
    enabled = function()
      -- NOTE: this is from https://github.com/hrsh7th/nvim-cmp/blob/93cf84f7deb2bdb640ffbb1d2f8d6d412a7aa558/lua/cmp/config/default.lua
      local disable_cmp_file_types = {"prompt","TelescopePrompt"}
      if vim.tbl_contains(disable_cmp_file_types,vim.bo.filetype) then
        return false
      end
      if vim.fn.reg_recording() ~= '' then
        return false
      end
      if vim.fn.reg_executing() ~= '' then
        return false
      end
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
      ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
      ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
      ["<Up>"] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i' }),
      ['<Down>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i' }),
      ["<C-a>"] = cmp.mapping.abort(),
      -- ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      -- ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-v>"] = cmp.mapping.close(),
      ["<F1>"] = cmp.mapping(function(fallback)
        cmp.confirm {select = true, behavior = cmp.ConfirmBehavior.Insert}
      end,{ "i", "c" }),
      ["<CR>"] = cmp.config.disable,
      ["<tab>"] = cmp.mapping(function(fallback)
        local words = before_words()
        if not words:match('%S') then
          -- return feedkeys('<TAB>')
          fallback()
        else
          cmp.complete()
        end
      end),
      ["<S-tab>"] = cmp.config.disable,
      -- ["<tab>"] = function(fallback)
      --   if cmp.visible() then
      --     cmp.select_next_item()
      --     -- remove this: separate mappings for luasnip and nvim-cmp
      --     -- elseif require'luasnip'.expand_or_jumpable() then
      --     --   vim.fn.feedkeys(t("<Plug>luasnip-expand-or-jump"), "")
      --   elseif check_back_space() then
      --     vim.fn.feedkeys(t("<tab>"), "n")
      --   else
      --     fallback()
      --   end
      -- end,
      -- ["<S-tab>"] = function(fallback)
      --   if cmp.visible() then
      --     cmp.select_prev_item()
      --     -- elseif require'luasnip'.jumpable(-1) then
      --     --   vim.fn.feedkeys(t("<Plug>luasnip-jump-prev"), "")
      --   else
      --     fallback()
      --   end
      -- end
    },
    sources = {
      { name = 'nvim_lua' },
      { name = "luasnip" },
      { name = "path"  },
      { 
        name = "nvim_lsp", 
        -- NOTE: example of filtering source
        -- entry_filter = function(entry, ctx)
        --   local cond = require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Text'
        --   cond = cond and require('cmp.types').lsp.CompletionItemKind[entry:get_kind()] ~= 'Snippet'
        --   return cond
        -- end
      },
      { name = 'nvim_lsp_signature_help' },
      { 
        name = "buffer", 
        keyword_length = 5,
        -- NOTE: this may slow down nvim
        option = {
          get_bufnrs = function()
            local win_bufs = require('core.utils').get_all_window_buffer_filetype()
            local bufs = {}
            for i, win_buf in ipairs(win_bufs) do
              table.insert(bufs, win_buf.bufnr)
            end
            return bufs
          --   local bufnrs = vim.tbl_filter(function(b)
          --     if 1 ~= vim.fn.buflisted(b) then
          --       return false
          --     end
          --     -- only hide unloaded buffers if opts.show_all_buffers is false, keep them listed if true or nil
          --     if not vim.api.nvim_buf_is_loaded(b) then
          --       return false
          --     end
          --     -- if not string.find(vim.api.nvim_buf_get_name(b), vim.loop.cwd(), 1, true) then
          --     --   return false
          --     -- end
          --     return true
          --   end, vim.api.nvim_list_bufs())
          -- return bufnrs
          end,
        }
      }
      -- { name = "mine_config_yaml", trigger_characters = { '.' } }, -- manually trigger
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
  }

  require('core.utils').map("i", "<C-q>",function ()
    if vim.g.cmp_enabled then
      require("cmp").close()
      vim.g.cmp_enabled = false
    else
      require('cmp').complete()
      vim.g.cmp_enabled = true
    end
  end)

  -- local cmp_rg_complete = function()
  --   cmp.complete({
  --     config = {
  --       sources = {
  --         { name = "rg" }, -- should install the cmp-rg
  --       }
  --     }
  --   })
  -- end
  -- require('core.utils').map('i','<C-g>',cmp_rg_complete,{noremap=true,silent=true})


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
return {}
