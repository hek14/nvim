local M = {
  "jose-elias-alvarez/null-ls.nvim"
}
function M.setup(options)
  local formatting = require("null-ls").builtins.formatting
  local diagnostics = require("null-ls").builtins.diagnostics
  local code_actions = require("null-ls").builtins.code_actions
  require("null-ls").setup({
    sources = {
      formatting.stylua.with({ extra_args = {"--indent-width=2"}}),
      code_actions.gitsigns,
      diagnostics.ruff.with({  extra_args = {"--ignore=F401,F811,E501,E402,E401,F541"} }),
      diagnostics.jsonlint,
    },
    -- on_attach = options.on_attach,
    root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", ".git"),
  })
end
return M
