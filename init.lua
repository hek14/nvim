local modules = {
   "core.options",
   "core.autocmds",
   "core.lazy",
   "core.keymap",
   "core.gui"
}

for _, module in ipairs(modules) do
  require(module)
end

_G.treesitter_job = require('scratch.bridge_ts_parse')
treesitter_job:batch(3)
