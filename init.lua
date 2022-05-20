--[=====[ TODO:
1. refer to following dotfiles:
1.1 https://github.com/RRethy/dotfiles/tree/master/nvim: the author of vim-illuminate
1.2 https://github.com/lucasvianav/nvim: nice hacking about lspconfig handlers
2. refer to useful plugins
2.1 interact with tmux: https://github.com/preservim/vimux
2.2 task system and run script, show output:
2.2.1 https://github.com/skywind3000/asynctasks.vim#installation
2.2.2 https://github.com/skywind3000/asyncrun.vim#extra-runners
3. themes: https://alpha2phi.medium.com/12-neovim-themes-with-tree-sitter-support-8be320b683a4
----]=====]

local present, impatient = pcall(require, "impatient")

if present then
   impatient.enable_profile()
end

local modules = {
   "utils",
   "options",
   "autocmds",
   "mappings",
}

for _, module in ipairs(modules) do
   local ok, err = pcall(require, "core." .. module)

   if not ok then
      error("Error loading " .. module .. "\n\n" .. err)
   end
end

require('core.mappings').general() -- load the mappings at the end of config to ensure it taking effects
require("core.lazy")
