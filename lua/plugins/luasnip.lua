-- NOTE:refer to https://www.youtube.com/watch?v=ub0REXjhpmk
local M = {
  "L3MON4D3/LuaSnip",
  event = 'InsertEnter',
  -- install jsregexp (optional!).
  build = "make install_jsregexp"
}
function M.config()
  local luasnip = require"luasnip"
  local map = require("core.utils").map
  local ls = require("luasnip")
  local line_breaker = function()
    return ls.t({"",""})
  end

  luasnip.config.setup {
    history = true,
    updateevents = "TextChanged,TextChangedI",
  }

  local au = require("core.autocmds").au
  au("InsertEnter", function()
    require("luasnip/loaders/from_vscode").lazy_load()
  end)
  require('luasnip.loaders.from_lua').lazy_load({ paths = vim.fn.stdpath('config') .. '/snippets' })

  -- <c-j> is my expansion key
  -- this will expand the current item or jump to the next item within the snippet.
  function _G.ls_Ctrl_j()
    if ls.expand_or_jumpable() then
      ls.expand_or_jump()
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
  map("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/lua/custom/pluginConfs/luasnip.lua<CR>")
end
return M
