for newly installed:
  1. install nvim nightly
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
