-- NOTE:refer to https://www.youtube.com/watch?v=ub0REXjhpmk
local present, luasnip = pcall(require, "luasnip")
local map = require("core.utils").map
if not present then
  print("luasnip not present")
  return 
end
luasnip.config.set_config {
  history = true,
  updateevents = "TextChanged,TextChangedI",
}

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
local fmt = require("luasnip.extras.fmt").fmt

local date = function() return {os.date('%Y-%m-%d')} end
local line_breaker = function()
  return t({"",""})
end

local line_replace = function(args,_,user_arg_1)
  local og_line = args[1][1]
  local line = string.gsub(og_line,user_arg_1['pat'],user_arg_1['sub'])
  line = string.gsub(line,vim.fn.toupper(user_arg_1['pat']), vim.fn.toupper(user_arg_1['sub']))
  return line
end

local function copy(args)
  return args[1]
end

local custom_snippets = {
  all = {
    s('pp',fmt([[
vim.pretty_print("{}: ",{}{})
    ]],{
        i(1,'variable'),
        f(function(args,_,_)
          return args[1][1]
        end,{1}),
        i(0)
      })),
    s("date",{
      f(date,{})
    }),
    s("sep", {
      f(function ()
        local raw = vim.fn.split(vim.o.commentstring,'%s')[1]
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
    }),
    s("ignore",{
      f(function ()
        local raw = vim.fn.split(vim.o.commentstring,'%s')[1]
        if string.sub(raw,#raw,#raw)~=" " then
          raw = raw .. " "
        end
        return raw
      end,{}),
      t("type: ignore")
    })
  },
  python = {
    s('pp',fmt([[
print("{}: ",{}{})
    ]],{
        i(1,'variable'),
        f(function(args,_,_)
          return args[1][1]
        end,{1}),
        i(0)
      })),
    s("cpu",{
      t"torch.device(\"cpu\")"
    }),
    s("gpu",{
      t"torch.device(\"cuda:",
      i(1),
      t"\")",
      i(0)
    }),
    s("fig",
      fmt([[
{}
fig,axes = plt.subplots({})
{}
{}
      ]],{
          f(function()
            local found = vim.fn.search("import matplotlib.pyplot as plt")
            if found > 0 then
              return ""
            else
              return "import matplotlib.pyplot as plt"
            end
          end,{}),
          i(1,"1"),
          d(2,function(args, _, old_state)
            local nodes = {}
            old_state = old_state or {}
            local ok,number = pcall(tonumber,args[1][1])
            if not ok then
              if type(old_state)=="number" then
                number = old_state
              else
                return
              end
            else
              print(number)
              for j=1,number do
                if j~=number then
                  nodes[j] = sn(j,{t("axes["),i(1,tostring(j-1)),t("].imshow("),i(2,""),t({")",""})})
                else
                  nodes[j] = sn(j,{t("axes["),i(1,tostring(j-1)),t("].imshow("),i(2,""),t(")")})
                end
              end
              local snip = sn(nil,nodes)
              snip.old_state = old_state
              return snip
            end
          end,{1}),
          c(3,{
            t("plt.show()"),
            sn(nil,{t"plt.savefig(",i(1),t")"})
          })
        }
      )),
    s("ypr",fmt([[
{}
{}
{}
    ]],{
        i(1,"yaw"),
        f(line_replace,{1},{user_args = {{pat='yaw',sub='pitch'}}}),
        f(line_replace,{1},{user_args = {{pat='yaw',sub='roll'}}}),
      })),
    s("yp",fmt([[
{}
{}
    ]],{
        i(1,"yaw"),
        f(line_replace,{1},{user_args = {{pat='yaw',sub='pitch'}}}),
      })),
    s("yr",fmt([[
{}
{}
    ]],{
        i(1,"yaw"),
        f(line_replace,{1},{user_args = {{pat='yaw',sub='roll'}}}),
      }))
  }
}

for k,v in pairs(custom_snippets) do
  ls.add_snippets(tostring(k),v)
end

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
