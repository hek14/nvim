---@diagnostic disable:  undefined-global
return {
  -- e.g. local bar = require("foo.bar")
  s('pp',fmt([[
  vim.print("{}: ",{}{})
  ]],{
    f(function(args,_,_)
      return args[1][1]
    end,{1}),
    i(1,'variable'),
    i(0)
  })),
  s(
    'require',
    fmt([[local {} = require("{}")]], {
      d(2, function(args)
        local modules = vim.split(args[1][1], '%.')
        return sn(nil, { i(1, modules[#modules]) })
      end, { 1 }),
      i(1),
    })
  ),
}
