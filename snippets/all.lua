local date = function() return {os.date('%Y-%m-%d')} end
return {
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
}
