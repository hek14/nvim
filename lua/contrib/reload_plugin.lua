local reload_a_plugins_all_modules = function(module_name)
local sub_modules = {}
for pack, _ in pairs(package.loaded) do
 if string.find(pack, "^" .. vim.pesc(module_name)) then
   table.insert(sub_modules,pack)
 end
end
table.sort(sub_modules,function(a,b)
  return #a > #b
end) -- NOTE: make the module itself the last

for i,m in ipairs(sub_modules) do
   local old = package.loaded[m]

   package.loaded[m] = nil
   require(m)

   local new = package.loaded[m]
   if i==#m-1 then
     break
   end
 end
 require(sub_modules[#sub_modules]).setup()
 end
