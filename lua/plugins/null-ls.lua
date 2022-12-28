local M = {
  "jose-elias-alvarez/null-ls.nvim"
}
function M.setup(options)
  local formatting = require("null-ls").builtins.formatting
  local diagnostics = require("null-ls").builtins.diagnostics
  local code_actions = require("null-ls").builtins.code_actions
  require("null-ls").setup({
    sources = {
      formatting.lua_format.with({ extra_args = {"--indent-width=2"}}),
      diagnostics.jsonlint,
      code_actions.gitsigns,
      -- formatting.black.with({ extra_args = {"--fast" }}),
    },
    -- on_attach = options.on_attach,
    root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", ".git"),
  })
end
return M
