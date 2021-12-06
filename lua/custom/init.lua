-- This is where your custom modules and plugins go.
-- See the wiki for a guide on how to extend NvChad

local hooks = require "core.hooks"

-- NOTE: To use this, make a copy with `cp example_init.lua init.lua`

--------------------------------------------------------------------

-- To modify packaged plugin configs, use the overrides functionality
-- if the override does not exist in the plugin config, make or request a PR,
-- or you can override the whole plugin config with 'chadrc' -> M.plugins.default_plugin_config_replace{}
-- this will run your config instead of the NvChad config for the given plugin

hooks.override("lsp", "publish_diagnostics", function(current)
  current.virtual_text = false;
  return current;
end)

-- To add new mappings, use the "setup_mappings" hook,
-- you can set one or many mappings
-- example below:

hooks.add("setup_mappings", function(map)
  map("n", "<leader>cd", "<cmd>:cd %:p:h<cr>", {silent=false}) -- example to delete the buffer
  map("n", "<leader>so", "<cmd>: lua Source_curr_file()<cr>", {silent=false}) -- example to delete the buffer

  map("n", "n", "j",   {silent=true,noremap=true}) -- example to delete the buffer
  map("x", "n", "j",   {silent=true,noremap=true}) -- example to delete the buffer
  map("n", "N", "J",   {silent=true,noremap=true}) -- example to delete the buffer
  map("x", "N", "J",   {silent=true,noremap=true}) -- example to delete the buffer
  map("n", "gn", "gj", {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "e", "k",   {silent=true,noremap=true}) -- example to delete the buffer
  map("x", "e", "k",   {silent=true,noremap=true}) -- example to delete the buffer
  map("n", "E", "K",   {silent=true,noremap=false}) -- example to delete the buffer
  map("x", "E", "K",   {silent=true,noremap=false}) -- example to delete the buffer
  map("n", "ge", "gk", {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "i",  "l",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "i",  "l",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "i",  "l",  {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "k",  "n",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "k",  "n",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "k",  "n",  {silent=false,noremap=true}) -- example to delete the buffer
  map("n", "K",  "N",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "K",  "N",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "K",  "N",  {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "u",  "i",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "u",  "i",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "u",  "i",  {silent=false,noremap=true}) -- example to delete the buffer
  map("n", "U",  "I",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "U",  "I",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "U",  "I",  {silent=false,noremap=true}) -- example to delete the buffer

  map("n", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("n", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("x", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer
  map("o", "l",  "u",  {silent=false,noremap=true}) -- example to delete the buffer

  map({"n","x"}, "<C-w>n", "<C-w>j", {silent=false,noremap=true})
  map({"n","x"}, "<C-w>e", "<C-w>k", {silent=false,noremap=true})
  map({"n","x"}, "<C-w>i", "<C-w>l", {silent=false,noremap=true})

  map("x", ">", ">gv", {silent=false,noremap=true})
  map("x", "<", "<gv", {silent=false,noremap=true})
end)

function Source_curr_file ()
  if vim.bo.ft == "lua" then
    vim.cmd[[luafile %]]
  elseif vim.bo.ft == "vim" then
    vim.cmd[[so %]]
  end
end

function _G.put(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, '\n'))
  return ...
end

-- To add new plugins, use the "install_plugin" hook,
-- NOTE: we heavily suggest using Packer's lazy loading (with the 'event' field)
-- see: https://github.com/wbthomason/packer.nvim
-- examples below:

hooks.add("install_plugins", function(use)
  use {
    "williamboman/nvim-lsp-installer",
  }
  use {
    'RishabhRD/nvim-lsputils',
    requires = 'RishabhRD/popfix',
    after = "nvim-lspconfig",
    config = require"custom.plugins.lsputils".setup
  }
  use {
    "ahmedkhalf/project.nvim",
    config = require"custom.plugins.project".setup
  }
  use {
    "tmhedberg/SimpylFold",
    config = function ()
      vim.g.SimpylFold_docstring_preview = 1
    end
  }
end
)

vim.cmd [[
  au BufRead * set foldlevel=99
]]

-- vim.api.nvim_del_keymap("o","i%")

-- alternatively, put this in a sub-folder like "lua/custom/plugins/mkdir"
-- then source it with

-- require "custom.plugins.mkdir"
