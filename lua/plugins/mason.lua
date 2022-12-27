local M = {
  "williamboman/mason.nvim",
}

M.tools = {
  "prettierd",
  "stylua",
  "selene",
  "luacheck",
  "eslint_d",
  "shellcheck",
  "deno",
  "shfmt",
  "black",
  "isort",
  "flake8",
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
