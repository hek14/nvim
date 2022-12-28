-- NOTE: manage all of the external tools that need to be installed by lsp/dap
local M = {
  "williamboman/mason.nvim",
}

M.tools = {
  "prettierd",
  "stylua",
  "luacheck",
  "shellcheck",
  "shfmt",
  "ruff",
  -- "isort",
  -- "flake8",
  -- "black",
  -- "selene",
  -- "eslint_d",
  -- "deno",
}

function M.check()
  local mr = require("mason-registry")
  for _, tool in ipairs(M.tools) do
    local p = mr.get_package(tool)
    if not p:is_installed() then
      p:install()
    end
  end
end

function M.config()
  M.check()
end

return M
