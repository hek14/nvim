# themes 
```text
  {
    "mhartington/oceanic-next",
    enabled = false,
    config = function ()
      vim.cmd[[ colorscheme OceanicNext ]]
    end
  },
  {
    "bluz71/vim-nightfly-guicolors",
    enabled = false,
    config = function ()
      vim.cmd [[colorscheme nightfly]]
    end
  },
  {
    "sainnhe/edge",
    enabled = false,
    event = 'VimEnter',
    config = function ()
      vim.cmd [[ colorscheme edge ]]
    end
  },
  {
    "Mofiqul/vscode.nvim",
    enabled = false,
    lazy = false,
    config = function ()
      vim.o.background = 'dark'
      local c = require('vscode.colors')
      require('vscode').setup({
        italic_comments = true,
      })
    end
  },
``` 

# font website
https://www.programmingfonts.org
https://www.codingfont.com/
https://www.nerdfonts.com/font-downloads

# for newly installed:
1. install nvim nightly
  1.1 wget -c xxx.tar.gz (from the github release page)
  1.2 extract xxx.tar.gz
  1.3 cd nvim-xxx
  1.4 cp bin/nvim /usr/local/bin/ (for mac-os)
      cp bin/nvim /usr/bin/ (for linux)
  1.5 cp -r share/nvim /usr/local/share/ (for mac-os)
      cp -r share/nvim /usr/share/ (for linux)
2. remove the ~/.cache/nvim and ~/.local/share/nvim
3. remove ~/.config/nvim/plugin/packer_compiled.lua
4. install dependencies
  treesitter-related: :TSInstall
  lsp-related: :LspInstall
5. install node>12.0 (for ubuntu, you need to install manually)
  5.1. curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
  5.2. sudo bash nodesource_setup.sh
  5.3. sudo apt-get update && sudo apt install nodejs
  5.4. node -v # check the version 
6. install shell dependencies:
  6.1. ripgrep
  6.2. fdfind
  6.3. zoxide

# refer to following dotfiles:
1. https://github.com/RRethy/dotfiles/tree/master/nvim: the author of vim-illuminate
2. https://github.com/lucasvianav/nvim: nice hacking about lspconfig handlers
3. https://github.com/leaxoy/dotfiles/tree/main/.config/nvim
4. https://github.com/glepnir/nvim.git
5. https://github.com/ziontee113/nvim-config: nice youtube vlog
6. https://github.com/s1n7ax/dotnvim: Power of LuaSnip with TreeSitter in Neovim
7. https://github.com/folke/dot/tree/master/config/nvim
8. https://github.com/williamboman/nvim-config: the author of mason.nvim
9. https://github.com/adoyle-h
10. https://github.com/JoosepAlviste/dotfiles: nice customizaion about telescope live_grep
11. https://github.com/joshmedeski/dotfiles: yabai,skhd,alacritty,tmux

# refer to useful plugins
1. https://github.com/anuvyklack/hydra.nvim: emacs hydra alternative for nvim! finally here
2. https://github.com/ziontee113/syntax-tree-surfer: navigater/swap based on syntax tree(powered by treesitter)
3. https://github.com/simrat39/symbols-outline.nvim: lsp symbols
4. https://github.com/jbyuki/one-small-step-for-vimkind: debug nvim instance itself!!!
5. https://github.com/williamboman/mason.nvim: a all-in-one lsp-installer and dap-installer
6. https://github.com/stevearc/overseer.nvim: yet another task manager
7. themes: https://alpha2phi.medium.com/12-neovim-themes-with-tree-sitter-support-8be320b683a4
8. https://github.com/cshuaimin/ssr.nvim: Structural search and replace for Neovim

# refer to other resources
1. jesse19skelton
- https://www.youtube.com/@jesse19skelton -- nice videos about karabiner and  yabai [his github]()
- https://www.youtube.com/watch?v=JL1lz77YbUE&ab_channel=JesseSkelton
- https://www.notion.so/Yabai-8da3b829872d432fac43181b7ff628fc

2. s1n7ax
https://www.youtube.com/@s1n7ax/videos


# for pyright completion stubs
https://github.com/bschnurr/python-type-stubs or https://github.com/microsoft/python-type-stubs
example: how to use it for cv2 module completion:
```shell
curl -sSL https://raw.githubusercontent.com/bschnurr/python-type-stubs/add-opencv/cv2/__init__.pyi \
  -o $(python -c 'import cv2, os; print(os.path.dirname(cv2.__file__))')/cv2.pyi
```

# help fillchars 
to change fold/endOfBuffer appearance

# inspecting options and variables
instead of using message buffer, just create a new buffer, and normal mode: `:put =bufnr()`, `put =@"` or insert mode: `CTRL_R=bufnr()`

# really useful keymap fix for neovim in kitty/alacritty:
1. video: https://www.youtube.com/watch?v=lHBD6pdJ-Ng
2. config files: https://github.com/ziontee113/yt-tutorials/tree/nvim_key_combos_in_alacritty_and_kitty
3. http://www.leonerd.org.uk/hacks/fixterms/
4. https://en.wikipedia.org/wiki/List_of_Unicode_characters

# nvim -V1
`:verbose map m` don't work in normal case for mappings defined in lua, you should start nvim using `nvim -V1`

# vim.loop
https://teukka.tech/posts/2020-01-07-vimloop/

# TODO: 
- learn `async await`: https://github.com/ms-jpq/lua-async-await and [lspsaga](https://github.com/glepnir/lspsaga.nvim)
- refer to https://jdhao.github.io/2019/03/26/nvim_latex_write_preview/ to setup vimtex on mac OS
