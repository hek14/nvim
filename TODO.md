# TODO: 
- resume-layout.nvim: 看看哪一些event会change window layout, 用gpt4辅助写:
1. 四组events需要insert hook，定义记录的data formats
WinEnter and WinLeave, BufWinEnter and BufWinLeave, TabEnter and TabLeave, BufEnter and BufLeave
2. 如何set window尺寸，函数是啥
- implement `RemoteExecute qingdao command output_file`
- check modern-unix shell tools: https://github.com/ibraheemdev/modern-unix
- check: https://github.com/quarto-dev/quarto-nvim
- check: https://github.com/3rd/image.nvim/
- AsyncRun: https://github.com/skywind3000/asyncrun.vim/wiki/Better-way-for-C-and-Cpp-development-in-Vim-8
- learn `async await`: https://github.com/ms-jpq/lua-async-await
- refer to https://jdhao.github.io/2019/03/26/nvim_latex_write_preview/ to setup vimtex on mac OS
- consider using https://github.com/justinmk/vim-dirvish to replace nvim-tree
- implement TogglePrintScope, TogglePrintFile command: use the custom_capture `print` and ask the user to choose: comment or not
