-- https://github.com/microsoft/pylance-release

local util = require("lspconfig.util")

local filter_path = function(paths)
  local index = 1
  for _,p in ipairs(paths) do
    if vim.loop.fs_stat(p) then
      paths[index] = p
      index = index + 1
    end
  end
  if index == 1 then
    if vim.loop.fs_stat(paths[1]) then
      return paths
    else
      return {}
    end
  end
  return paths
end

local table_combine = function(table1,table2)
  for i,p in ipairs(table2) do
    table1[#table1+i] = p
  end
  return table1
end

local get_script_path = function()
    -- NOTE: node version should be lastest, unless an error `Unexpected token` will occur
    local scripts = vim.fn.expand("$HOME/github/ms-python.vscode-pylance-*/dist/server.bundle.js", false, true)
    scripts = filter_path(scripts)
    if #scripts == 0 then
      error("Failed to resolve path to Pylance server")
      return nil
    end
    return scripts[1]
end

local cmd = { "node", get_script_path(), "--stdio" }

return {
    default_config = {
        name = "pylance",
        autostart = true,
        single_file_support = true,
        cmd = cmd,
        filetypes = { "python" },
        root_dir = function(fname)
            local markers = {
                "Pipfile",
                "pyproject.toml",
                "pyrightconfig.json",
                "setup.py",
                "setup.cfg",
                "requirements.txt",
            }
            return util.root_pattern(unpack(markers))(fname)
                or util.find_git_ancestor(fname)
                or util.path.dirname(fname)
        end,
        settings = {
            python = {
                analysis = vim.empty_dict(),
            },
            telemetry = {
                telemetryLevel = "off",
            },
        },
        docs = {
            package_json = vim.fn.expand(
                "$HOME/github/ms-python.vscode-pylance-*/package.json",
                false,
                true
            )[1],
            description = [[
      https://github.com/microsoft/pyright
      `pyright`, a static type checker and language server for python
      ]],
        },
    },
}
