--[=====[ TODO:
1. refer to following dotfiles:
1.1 https://github.com/RRethy/dotfiles/tree/master/nvim: the author of vim-illuminate
1.2 https://github.com/lucasvianav/nvim: nice hacking about lspconfig handlers
1.3 https://github.com/leaxoy/v
1.4 https://github.com/glepnir/nvim.git
1.5 https://github.com/ziontee113/nvim-config -- nice youtube vlog
1.6 https://github.com/s1n7ax/dotnvim: Power of LuaSnip with TreeSitter in Neovim
1.7 https://github.com/folke/dot/tree/master/config/nvim: hack packer for local plugins
2. refer to useful plugins
2.1 https://github.com/anuvyklack/hydra.nvim: emacs hydra alternative for nvim! finally here
2.2 https://github.com/ziontee113/syntax-tree-surfer: navigater/swap based on syntax tree(powered by treesitter)
2.3 https://github.com/simrat39/symbols-outline.nvim: lsp symbols
2.4 https://github.com/jbyuki/one-small-step-for-vimkind: debug nvim instance itself!!!
2.5 https://github.com/williamboman/mason.nvim: a all-in-one lsp-installer and dap-installer
2.6 https://github.com/stevearc/overseer.nvim: yet another task manager
3. themes: https://alpha2phi.medium.com/12-neovim-themes-with-tree-sitter-support-8be320b683a4
4. for pyright completion stubs: https://github.com/bschnurr/python-type-stubs or https://github.com/microsoft/python-type-stubs
4.1 how to use it for cv2 module completion:
  ```shell
  curl -sSL https://raw.githubusercontent.com/bschnurr/python-type-stubs/add-opencv/cv2/__init__.pyi \
    -o $(python -c 'import cv2, os; print(os.path.dirname(cv2.__file__))')/cv2.pyi
  ```
5. :help fillchars to change fold/endOfBuffer appearance
6. one tip for inspecting options and variables: instead of using message buffer, just create a new buffer, and normal mode: `:put =bufnr()`, `put =@"` or insert mode: `CTRL_R=bufnr()`
7. really useful keymap fix for neovim in kitty/alacritty:
7.1 video: https://www.youtube.com/watch?v=lHBD6pdJ-Ng
7.2 config files: https://github.com/ziontee113/yt-tutorials/tree/nvim_key_combos_in_alacritty_and_kitty
7.3 http://www.leonerd.org.uk/hacks/fixterms/
7.4 https://en.wikipedia.org/wiki/List_of_Unicode_characters
8. NOTE: `:verbose map m` don't work in normal case for mappings defined in lua, you should start nvim using `nvim -V1`
9. `vim.loop`: https://teukka.tech/posts/2020-01-07-vimloop/
10. TODO: PLEASE learn this: `async await`: https://github.com/ms-jpq/lua-async-await and [lspsaga](https://github.com/glepnir/lspsaga.nvim)

- HOT TODO:
1. refer to https://github.com/glepnir/nvim/blob/main/lua/core/pack.lua
2. refer to https://jdhao.github.io/2019/03/26/nvim_latex_write_preview/ to setup vimtex on mac OS
----]=====]
debug_rc = false
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
-- require("core.lazy")
