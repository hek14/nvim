-- defer_fn target will wait until the end of current context(here: is the nvim init process)
-- to further understand the defer_fn: it's a one-shot timer, and the target function is automatically schedule_wrapped
vim.defer_fn(function ()
  print(vim.is_thread()) -- vim.defer_fn is not about multi-thread, it's just scheduling the function later in the main event loop
  vim.defer_fn(function ()
    print(vim.is_thread())
    print("in the inner defer_fn")
  end,0)
  print('testing defer_fn 1')
  print('testing defer_fn 2')
  print('ending the defer_fn')
end,0)
print("the main function")
