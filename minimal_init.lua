---< maps
local lhs = "neilukj"
local rhs = "jkluine"
local modes = {"n","x","o"}
local opt = {silent=true,noremap=true}
for i = 1,#lhs do
  local colemak = lhs:sub(i,i)
  local qwerty  = rhs:sub(i,i)
  for _,mode in ipairs(modes) do
    vim.api.nvim_set_keymap(mode,colemak,qwerty,opt)
    vim.api.nvim_set_keymap(mode,vim.fn.toupper(colemak),vim.fn.toupper(qwerty),opt)
    if i < 4 then -- for direction keys
      vim.api.nvim_set_keymap(mode,"<C-w>" .. colemak,"<C-w>" .. qwerty,opt)
      vim.api.nvim_set_keymap(mode,"<C-w><C-" .. colemak .. ">","<C-w><C-" .. qwerty .. ">",opt)
    end
  end
end
vim.api.nvim_set_keymap('n',"<Esc>",':noh<CR>',{silent=true,noremap=true})
---> maps end

---< options
vim.o.ignorecase = true
vim.o.number = true
vim.o.relativenumber = true
vim.opt.expandtab = true
vim.opt.ts = 4
vim.opt.sw = 4
vim.opt.autoindent = true
vim.g.no_plugin_maps = true
---> options end
