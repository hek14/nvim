require'core.options'
require'core.autocmds'
require'core.lazy'
require'core.keymap'
require'core.gui'

--[[
Some hacking scripts of this config

  - lua/scratch/bridge_ts_parse.lua
    use another backend neovim process to do heavy treesitter stuff asynchronously.
    To enable it:
      _G.treesitter_job = require('scratch.bridge_ts_parse')
      treesitter_job:batch(1)

  - lua/scratch/repl.lua
    send current line to repl, including python, lua, r, rust, etc.

  - lua/contrib/statusline
    my own statusline

  - lua/scratch/job_util.lua
    wrapper of the native vim.fn.jobstart

--]]
