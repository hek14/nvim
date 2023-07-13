local map = require("core.utils").map
-- NOTE:refer to https://www.youtube.com/watch?v=ub0REXjhpmk
-- NOTE:refer to https://www.youtube.com/watch?v=OIMPbNSxXbw&ab_channel=s1n7ax
local M = {
  "L3MON4D3/LuaSnip",
  event = 'InsertEnter',
}

function M.config()
  -- help: `:help luasnip-config-reference`
  local ls = require("luasnip")
  local types = require("luasnip.util.types")
  ls.setup({
    history = true,
    update_events = {"TextChanged", "TextChangedI"},
    region_check_events = {'InsertEnter','CursorMoved'},
    delete_check_events = {'TextChanged','InsertLeave'},
    ext_opts = {
      [types.insertNode] = {
        active = { hl_group = "LspInfoTip" },
        visited = { hl_group = 'Visual' },
        passive = { hl_group = 'Visual' },
        snippet_passive = { hl_group = 'Visual' }
      },
      [types.choiceNode] = {
        active = {  hl_group = "Visual" },
        unvisited = { hl_group = 'Visual' }
      },
      [types.snippet] = {
        -- passive = { hl_group = 'LspInfoTip' }
      }
    },
    ext_base_prio = 200,
    ext_prio_increase = 2
  })
  require("luasnip.loaders.from_vscode").lazy_load({ paths = {'~/.config/nvim/snippets/vscode', '~/.local/share/nvim/lazy/friendly-snippets'} })
  require('luasnip.loaders.from_lua').lazy_load({ paths = vim.fn.stdpath('config') .. '/snippets' })

  -- exit snippet, should be used with the delete_check_events,region_check_events,update_events
  map({'i','s'},'<C-u>',function ()
    ls.unlink_current()
  end,{silent=false})
  local line_breaker = function()
    return ls.t({"",""})
  end
  map({ "i", "s" }, "<c-y>", function()
    if ls.expandable() then 
      ls.expand()
    end
  end, { silent = true })
  map({ "i", "s" }, "<c-j>", function()
    if ls.jumpable(1) then
      ls.jump(1)
    else
    end
  end, { silent = true })
  map({ "i", "s" }, "<c-k>", function()
    if ls.jumpable(-1) then
      ls.jump(-1)
    end
  end, { silent = true })
  map({"i","s"}, "<c-l>", function()
    if ls.choice_active() then
      ls.change_choice(1)
    end
  end)
  -- reload my snippets
  -- map("n", "<leader><leader>s",function ()
  --   require('luasnip.loaders.from_lua').lazy_load({ paths = vim.fn.stdpath('config') .. '/snippets' })
  -- end)
end
return M
