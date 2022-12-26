-- providing extra formatting and linting
-- NullLsInfo to show what's now enabled
-- Remember: you should install formatters/linters in $PATH, null-ls will not do this for you.
-- if other formatting method is enabled by the lspconfig(pyright for example), then you should turn that of in the on_attach function like below:
-- function on_attach(client,bufnr)
--    if client.name = "pyright" then
--         client.server_capabilities.document_formatting = false
--    end
-- end
local M = {
  "jose-elias-alvarez/null-ls.nvim"
}
function M.setup(options)
  local formatting = require("null-ls").builtins.formatting
  local diagnostics = require("null-ls").builtins.diagnostics
  local code_actions = require("null-ls").builtins.code_actions
  require("null-ls").setup({
    sources = {
      formatting.lua_format.with({ extra_args = {"--indent-width=4"}}),
      formatting.black.with({ extra_args = {"--fast" }}),
      code_actions.gitsigns,
    },
    on_attach = options.on_attach,
    root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", ".git"),
  })
end
return M
