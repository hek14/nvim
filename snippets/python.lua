---@diagnostic disable:  undefined-global
local rep = require("luasnip.extras").rep
local line_replace = function(args,_,user_arg_1)
  local og_line = args[1][1]
  local line = string.gsub(og_line,user_arg_1['pat'],user_arg_1['sub'])
  line = string.gsub(line,vim.fn.toupper(user_arg_1['pat']), vim.fn.toupper(user_arg_1['sub']))
  return line
end

local buf_lines = function(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local search_line = function(line)
  local lines = buf_lines(vim.api.nvim_get_current_buf())
  for _,each_line in ipairs(lines) do
    if each_line == line then
      return true
    end
  end
  return false
end

return {
  s('##',fmt([[
  {}
  # {}
  ]],{
    f(function(args,_,user_args)
      return string.rep('#',#args[1][1]+2)
    end,{1}),
    i(1,"section"),
  })),
  s('pp',fmt([[
  print("{}: ",{}{})
  ]],{
    f(function(args,_,_)
      return args[1][1]
    end,{1}),
    i(1,'variable'),
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
  s("fig1",
  fmt([[
  fig,axes = plt.subplots({})
  {}
  {}
  {}
  ]],{
    i(1,"1"),
    d(2,function(args,_,old_state)
      -- old_state is a customized data, you can define anything here to avoid failed snipped expansion
      local nodes = {}
      old_state = old_state or 1
      local number = tonumber(args[1][1])
      if number==nil then
        number = old_state
        -- NOTE: do not `return` here, return will exit the whole snippet
      end
      if number == 1 then
        nodes[1] = sn(nil,{t"axes.imshow(",i(1,""),t")"})
        return sn(nil,nodes)
      end
      for j=1,number do
        if j~=number then
          nodes[j] = sn(j,{t(string.format("axes[%s].imshow(",j-1)),i(1,""),t({")",""})})
        else
          nodes[j] = sn(j,{t(string.format("axes[%s].imshow(",j-1)),i(1,""),t(")")})
        end
      end
      local snip = sn(nil,nodes)
      snip.old_state = number -- NOTE: store th
      return snip
    end,{1}),
    c(3,{
      t("plt.show()"),
      sn(nil,{t"plt.savefig(",i(1),t")"})
    }),
    i(0)
  }),
  {
    -- NOTE: do some dynamic/context-wise things here
    callbacks = {
    [-1] = {
      [events.pre_expand] = function (snippet, event_args)
        local found = search_line('import matplotlib.pyplot as plt')
        if not found then
          print("matplotlib not found, insert it at the beginning")
          vim.api.nvim_buf_set_lines(0,0,0,false,{'import matplotlib.pyplot as plt'})
        end
      end
    }}}),
  s("fig2",
  fmt([[
  fig,axes = plt.subplots({})
  {}
  {}
  ]],{
    i(1,"2,2"),
    -- old_State 不太好重置
    d(2,function(args,_,old_state)
      old_state = old_state or {2,2}
      local nodes = {}
      local str = string.gsub(args[1][1],' ','')
      local numbers = require('core.utils').stringSplit(str,',')
      numbers[1] = tonumber(numbers[1])
      numbers[2] = tonumber(numbers[2])
      if #numbers~=2 or type(numbers[1])~='number' or type(numbers[2])~='number' then
        numbers = old_state
      end
      for k=1,numbers[1] do
        for j=1,numbers[2] do
          if k==numbers[1] and j==numbers[2] then
            table.insert(nodes,sn((k-1)*numbers[2]+j ,{t(string.format("axes[%s,%s].imshow(",k-1,j-1)),i(1,""),t(")")}))
          else
            table.insert(nodes,sn((k-1)*numbers[2]+j,{t(string.format("axes[%s,%s].imshow(",k-1,j-1)),i(1,""),t({")",""})}))
          end
        end
      end
      local snip = sn(nil,nodes)
      snip.old_state = numbers
      return snip
    end,{1}),
    c(3,{
      t("plt.show()"),
      sn(nil,{t"plt.savefig(",i(1),t")"})
    })
  }),
  {
    -- NOTE: do some dynamic/context-wise things here
    callbacks = {
      [-1] = {
        [events.pre_expand] = function (snippet, event_args)
          local found = search_line('import matplotlib.pyplot as plt')
          if not found then
            print("matplotlib not found, insert it at the beginning")
            vim.api.nvim_buf_set_lines(0,0,0,false,{'import matplotlib.pyplot as plt'})
          end
        end
      }}}),
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
  })),
  s("init",fmt([[
  def __init__(self,{}):
      super({},self).__init__({})
  ]],{
    i(1),
    d(2,function(args, parent, old_state, initial_text)
      local class_name = require("contrib.treesitter.python").get_class_name()
      print('cls name: ',class_name)
      if class_name==nil then
        return sn(nil,{i(1,'class_name')})
      else
        return sn(nil,{t(class_name)})
      end
    end,{},{user_args = {}}),
    rep(1)
  })),
  s("nor",fmt(
  [[
  {} = ({} - {}.min()) / ({}.max() - {}.min() + 1e-6)
  ]],
  {
    d(2,function(args,_,_)
      return sn(nil,{i(1,args[1][1])})
    end,{1}),
    -- f(function(args,_,_)
    --   return args[1][1]
    -- end,{1}),
    i(1),
    rep(1),
    rep(1),
    rep(1)
  }))
}
