local M = {}
require('core.utils').append_env_path(vim.env['HOME'] .. '/.cargo/bin')
M.setup = function(options)
  local opts = {
    settings = {
      texlab = {
        build = {
          args = {
            "-xelatex", "-verbose", "-file-line-error",
            "-synctex=1", "-interaction=nonstopmode", "%f"
          },
          executable = "latexmk",
          forwardSearchAfter = true
        },
        chktex = {onOpenAndSave = true},
        forwardSearch = {
          args = {"--synctex-forward", "%l:1:%f", "%p"},
          executable = "zathura"
        }
      }
    }
  }
  opts = vim.tbl_deep_extend('force',options,opts)
  require("lspconfig").texlab.setup(opts)
end
return M
