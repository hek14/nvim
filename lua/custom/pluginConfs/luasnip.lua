local present, luasnip = pcall(require, "luasnip")
local chadrc_config = require'core.utils'.load_config()
if present then
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
    },
    python = {
      s("cpu",{
        t"torch.device(\"cpu\")"
      }),
      s("gpu",{
        t"torch.device(\"gpu:",
        i(1),
        t"\")",
        i(0)
      }),
    }
  }
end
