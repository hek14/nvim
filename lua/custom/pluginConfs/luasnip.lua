local present, luasnip = pcall(require, "luasnip")
local map = require("core.utils").map
local chadrc_config = require'core.utils'.load_config()
if not present then
  print("luasnip not present")
  return 
end
luasnip.config.set_config {
  history = true,
  updateevents = "TextChanged,TextChangedI",
}

require("luasnip/loaders/from_vscode").load { paths = chadrc_config.plugins.options.luasnip.snippet_path }
require("luasnip/loaders/from_vscode").load()

local ls = require("luasnip")
-- some shorthands...
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node

local date = function() return {os.date('%Y-%m-%d')} end
local function copy(args)
  return args[1]
end

ls.snippets = {
  all = {
    s("date",{
      f(date,{})
    }),
    s("sep", {
      f(function ()
        local raw = vim.fn.split(vim.o.commentstring,'%s')[1]
        print(string.sub(raw,#raw,#raw)==" ")
        if string.sub(raw,#raw,#raw)~=" " then
          raw = raw .. " "
        end
        return raw
      end,{}),
      t("========== "),
      i(0,"NOTE")
    }),
    s("pwd",{
      f(function ()
        return vim.loop.cwd()
      end,{}),
    })
  },
  python = {
    s("cpu",{
      t"torch.device(\"cpu\")"
    }),
    s("gpu",{
      t"torch.device(\"cuda:",
      i(1),
      t"\")",
      i(0)
    }),
    s("ignore",{
      t"# type: ignore",
    }),
  }
}

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
-- map("i", "<c-i>", function()
--   if ls.choice_active() then
--     ls.change_choice(1)
--   end
-- end)

-- shorcut to source my luasnips file again, which will reload my snippets
map("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/lua/custom/pluginConfs/luasnip.lua<CR>")
