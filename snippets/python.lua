local line_replace = function(args,_,user_arg_1)
  local og_line = args[1][1]
  local line = string.gsub(og_line,user_arg_1['pat'],user_arg_1['sub'])
  line = string.gsub(line,vim.fn.toupper(user_arg_1['pat']), vim.fn.toupper(user_arg_1['sub']))
  return line
end

return {
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
  })),
  s("init",fmt([[
  def __init__(self,{})
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
  }))
}
