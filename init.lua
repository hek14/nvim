-- try to call custom init
local ok, _ = pcall(require, "custom")
print("custom loaded: " .. tostring(ok))

if not ok then
  print(vim.inspect(debug.traceback()))
end

local core_modules = {
   "core.options",
   "core.autocmds",
   "core.mappings",
}

for _, module in ipairs(core_modules) do
   local ok, err = pcall(require, module)
   if not ok then
      error("Error loading " .. module .. "\n\n" .. err)
   end
end

-- non plugin mappings
require("core.mappings").misc()
