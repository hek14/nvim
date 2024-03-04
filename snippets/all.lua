---@diagnostic disable:  undefined-global
local date = function() return {os.date('%Y-%m-%d')} end
local ppp = fmt([[
printf("{}", {});
]],{
  i(1,""),
  d(2,function(args,_,_,user_args_1, user_args_2)
    local offset = 0
    local cnt = 0
    offset = string.find(args[1][1], [[%%]], offset)
    while offset do
      cnt = cnt + 1;
      offset = string.find(args[1][1], '%%', offset+1)
    end

    local nodes = {}
    for j = 1,cnt do
      local a_var
      if j < cnt then
        a_var = sn(j, {i(1, "var"), t(", ")})
      else
        a_var = i(j, "var")
      end
      table.insert(nodes, a_var)
    end
    return sn(nil,nodes)
  end,{1},{user_args = {{test="good"},{test2="bad"}}}),
})

return {
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
  }),
  s("ppp",ppp)
}
