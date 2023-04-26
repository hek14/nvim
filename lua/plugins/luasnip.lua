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
    region_check_events = {'InsertEnter'},
    delete_check_events = {'TextChanged'},
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
  map({'i','n'},'<C-e>',function ()
    if ls.in_snippet() then
      ls.unlink_current()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-e>',true,false,true),'n',false)
    end
  end,{silent=false})
  local line_breaker = function()
    return ls.t({"",""})
  end

  local au = require("core.autocmds").au
  require("luasnip/loaders/from_vscode").lazy_load()
  require('luasnip.loaders.from_lua').lazy_load({ paths = vim.fn.stdpath('config') .. '/snippets' })

  function _G.ctrl_d()
    if ls.expand_or_jumpable() then 
      ls.expand_or_jump()
    end
  end
  map({ "i", "s" }, "<c-d>", "<Cmd>lua ctrl_d()<CR>", { silent = true })
  -- <c-j> is my expansion key
  -- this will expand the current item or jump to the next item within the snippet.
  function _G.ls_Ctrl_j()
    if ls.jumpable(1) then
      ls.jump(1)
    end
  end

  map({ "i", "s" }, "<c-j>", "<Cmd>lua ls_Ctrl_j()<CR>", { silent = true })
  -- <c-k> is my jump backwards key.
  -- this always moves to the previous item within the snippet
  function _G.ls_Ctrl_k()
    if ls.jumpable(-1) then
      ls.jump(-1)
    end
  end
  map({ "i", "s" }, "<c-k>", "<Cmd>lua ls_Ctrl_k()<CR>", { silent = true })

  -- <c-i> is selecting within a list of options.
  -- This is useful for choice nodes (introduced in the forthcoming episode 2)
  map({"i","s"}, "<c-y>", function()
    if ls.choice_active() then
      ls.change_choice(1)
    end
  end)

  -- shorcut to source my luasnips file again, which will reload my snippets
  map("n", "<leader><leader>s",function ()
    require('luasnip.loaders.from_lua').lazy_load({ paths = vim.fn.stdpath('config') .. '/snippets' })
  end)
end
return M
