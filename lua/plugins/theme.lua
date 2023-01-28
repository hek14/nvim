local catppuccin = {
  "catppuccin/nvim",
  name = "catppuccin",
  event = "VeryLazy",
  enabled = false
}

function catppuccin.config()
  local ucolors = require "catppuccin.utils.colors"
  local latte = require("catppuccin.palettes").get_palette "latte"
  local frappe = require("catppuccin.palettes").get_palette "frappe"
  local macchiato = require("catppuccin.palettes").get_palette "macchiato"
  local mocha = require("catppuccin.palettes").get_palette "mocha"

  vim.g.catppuccin_flavour = "macchiato"
  local colors = require("catppuccin.palettes").get_palette() -- return vim.g.catppuccin_flavour palette

  require("catppuccin").setup {
    highlight_overrides = {
      all = {
        CmpBorder = { fg = "#687fb3" },
        Visual = { style = {'bold'}, bg = "#36497d" },
        Search = { bg = "#7932a8", fg = "#1E2030" }
      },
      latte = {
        Normal = { fg = ucolors.darken(latte.base, 0.7, latte.mantle) },
      },
      frappe = {
        TSConstBuiltin = { fg = frappe.peach, style = {} },
        TSConstant = { fg = frappe.sky },
        TSComment = { fg = frappe.surface2, style = { "italic" } },
      },
      macchiato = {
        LineNr = { fg = macchiato.overlay1 }
      },
      mocha = {
        Comment = { fg = mocha.flamingo },
      },
    },
  }
  vim.cmd [[ colorscheme catppuccin ]]
end


local kanagawa = {
  "rebelot/kanagawa.nvim",
  event = 'VeryLazy',
  config = function ()
    require('kanagawa').setup()
    vim.cmd [[ colorscheme kanagawa ]]
  end
}

return kanagawa
