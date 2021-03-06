local M = {}

M.setup = function ()
  require("project_nvim").setup {
    -- Manual mode doesn't automatically change your root directory, so you have
    -- the option to manually do so using `:ProjectRoot` command.
    manual_mode = false,

    -- Methods of detecting the root directory. **"lsp"** uses the native neovim
    -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
    -- order matters: if one is not detected, the other is used as fallback. You
    -- can also delete or rearangne the detection methods.

    -- important FIX: remove lsp detection, just using the pattern, because WinEnter autocmd not working well with the lsp detection
    detection_methods = { "pattern" }, 

    -- All the patterns used to detect root dir, when **"pattern"** is in
    -- detection_methods
    patterns = { ".git", ".project", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "main.py", "trainer*.py"},

    -- Table of lsp clients to ignore by name
    -- eg: { "efm", ... }
    ignore_lsp = {'efm'}, -- and do :LspUninstall efm too

    -- Don't calculate root dir on specific directories
    -- Ex: { "~/.cargo/*", ... }
    exclude_dirs = {},

    -- Show hidden files in telescope
    show_hidden = false,

    -- When set to false, you will get a message when project.nvim changes your
    -- directory.
    silent_chdir = true,

    -- Path where project.nvim will store the project history for use in
    -- telescope
    datapath = vim.fn.stdpath("data"),
  }
  require('core.utils').map("n","<leader>fp","<cmd>Telescope projects<CR>")
  -- important: just change root per window
  vim.cmd[[autocmd WinEnter * ++nested lua require("project_nvim.project").on_buf_enter()]]
end

return M
