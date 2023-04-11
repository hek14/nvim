local modules = {
  'core.options',
  'core.autocmds',
  'core.lazy',
  'core.keymap',
  'core.gui',
  'scratch.repl'
}

for _, module in ipairs(modules) do
  require(module)
end

_G.treesitter_job = require('scratch.bridge_ts_parse')
treesitter_job:batch(3)
-- TODO: python repl follow the current buffer? continue to develop ~/.config/nvim/lua/scratch/repl.lua
-- TODO: don't spawn the quickfix window in vimtex when there is only warning.
-- TODO: from git chunks to skim/zathura pdf highlights notations, applescript?
-- TODO: write visual model @: repeat #selected_lines times(use utils.get_line), begin at the `[
