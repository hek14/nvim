local present, cmp = pcall(require, "cmp")

if not present then
   return
end

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

cmp.setup {
   snippet = {
      expand = function(args)
         require("luasnip").lsp_expand(args.body)
      end,
   },
   formatting = {
      format = function(entry, vim_item)
         local icons = require "plugins.configs.lspkind_icons"
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
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<C-n>"] = cmp.mapping.select_next_item(),
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
      { name = "mine_config_yaml", trigger_characters = { '.' } },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "nvim_lua" },
      { name = "path" },
      { name = "latex_symbols"}
   },
}
_G.vimrc = _G.vimrc or {}
_G.vimrc.cmp = _G.vimrc.cmp or {}
_G.vimrc.cmp.mine = function()
  cmp.complete({
    config = {
      sources = {
        { name = "mine_config_yaml" },
      }
    }
  })
end

_G.vimrc.cmp.rg = function()
  cmp.complete({
    config = {
      sources = {
        { name = "rg" }, -- should install the cmp-rg
      }
    }
  })
end
vim.cmd([[
  inoremap <C-l> <Cmd>lua vimrc.cmp.mine()<CR>
]])
