return {
  "glepnir/lspsaga.nvim",
  event = "BufRead",
  config = function()
    require("lspsaga").setup({
      symbol_in_winbar = { enable = true }
    })
  end,
  dependencies = {
    {"nvim-tree/nvim-web-devicons"},
    {"nvim-treesitter/nvim-treesitter"}
  }
}
