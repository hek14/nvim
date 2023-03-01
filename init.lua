local modules = {
   "core.utils",
   "core.options",
   "core.lazy",
   "core.autocmds",
   "core.keymap",
   "core.gui"
}

for _, module in ipairs(modules) do
  require(module)
end
_G.p = require('contrib.print_to_buf').liveprint
