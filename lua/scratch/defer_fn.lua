-- defer_fn target will wait until the end of current context(here: is the nvim init process)
-- to further understand the defer_fn: it's a one-shot timer, and the target function is automatically schedule_wrapped
vim.defer_fn(function ()
  print(vim.is_thread()) -- vim.defer_fn is not about multi-thread, it's just scheduling the function later in the main event loop
  vim.defer_fn(function ()
    vim.defer_fn(function ()
      print('3_1',vim.loop.now())
    end,0)
    print("2_1",vim.loop.now())
  end,0)
  print('1_1',vim.loop.now())
end,0)

vim.defer_fn(function ()
  print('1_2',vim.loop.now())
end,0)
print("0",vim.loop.now())
print("0_1",vim.loop.now())
print("0_2",vim.loop.now())
