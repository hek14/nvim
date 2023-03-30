local date = function() return {os.date('%Y-%m-%d')} end
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
  })
}
