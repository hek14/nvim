local lprint = require("core.utils").log
-- deprecated: use :Lazy profile instead
-- vim.api.nvim_create_autocmd("UIEnter", {
--   callback = function()
--     local is_mac = vim.loop.os_uname().sysname=="Darwin"
--     if is_mac then
--       print('please use startuptime to profile')
--       return
--     else
--       local pid = vim.loop.os_getpid()
--       local ctime = vim.loop.fs_stat("/proc/" .. pid).ctime
--       local start = ctime.sec + ctime.nsec / 1e9
--       local tod = { vim.loop.gettimeofday() }
--       local now = tod[1] + tod[2] / 1e6
--       local startuptime = (now - start) * 1000
--       vim.notify("startup: " .. startuptime .. "ms")
--     end
--   end,
-- })
function Buf_attach()
  -- reset keymaps
  vim.defer_fn(function ()
    local cmd_str = [[xunmap <buffer> ih]] -- NOTES: xunmap ih will not work in this case!!! buffer local keymaps should unmap using <buffer> too
    local ok_all = true
    lprint(cmd_str)
    local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[ounmap <buffer> ih]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[xunmap i%]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok

    cmd_str = [[ounmap i%]]
    lprint(cmd_str)
    ok,_ = pcall(vim.api.nvim_command,cmd_str)
    ok_all = ok_all and ok
  end,250) -- 250 should be enough for buffer local plugins to load
  -- require("core.utils").repeat_timer(function ()
    --   local bufnr = vim.api.nvim_get_current_buf()
    --   if vim.api.nvim_buf_is_valid(bufnr) then
    --     local ok,timer = pcall(vim.api.nvim_buf_get_var,bufnr,'timer')
    --     if not ok then
    --       timer = 0
    --     else
    --       timer = vim.api.nvim_buf_get_var(bufnr,'timer')
    --     end
    --     local ok_all = true
    --
    --     local cmd_str = [[xunmap <buffer> ih]] -- NOTES: xunmap ih will not work in this case!!! buffer local keymaps should unmap using <buffer> too
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[ounmap <buffer> ih]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[xunmap i%]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     local cmd_str = [[ounmap i%]]
    --     lprint(cmd_str)
    --     local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     ok_all = ok_all and ok
    --
    --     -- local cmd_str = [[lua vim.api.nvim_buf_del_keymap(]] .. tostring(bufnr) .. [[ , 'x' , 'i%')]]
    --     -- lprint(cmd_str)
    --     -- local ok,_ = pcall(vim.api.nvim_command,cmd_str)
    --     -- ok_all = ok_all and ok
    --
    --     if packer_plugins['vim-matchup'].loaded then
    --       vim.api.nvim_buf_set_keymap(bufnr,'x','u%','<Plug>(matchup-i%)',{silent=true, noremap=false})
    --     end
    --     if packer_plugins['gitsigns.nvim'].loaded then
    --       vim.api.nvim_buf_set_keymap(bufnr,'x','uh',':<C-U>Gitsigns select_hunk<CR>',{silent=true, noremap=false})
    --       vim.api.nvim_buf_set_keymap(bufnr,'o','uh',':<C-U>Gitsigns select_hunk<CR>',{silent=true, noremap=false})
    --     end
    --     if ok then
    --       return -1
    --     else
    --       if timer<300 then
    --         vim.api.nvim_buf_set_var(bufnr,"timer",timer+10)
    --         return 10
    --       else
    --         return -1
    --       end
    --     end
    --   end
    -- end)
  end
vim.cmd([[autocmd BufEnter * lua Buf_attach()]])
