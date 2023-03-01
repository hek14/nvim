local override_hl = function ()
  vim.cmd([[
  hi clear CursorLine
  hi default LspReferenceRead ctermbg=237 guibg=#343d46
  hi default LspReferenceText ctermbg=237 guibg=#343d46
  hi default LspReferenceWrite ctermbg=237 guibg=#343d46 gui=Bold,Italic
  ]])
end

local catppuccin = {
  "catppuccin/nvim",
  name = "catppuccin",
  event = "VeryLazy",
  config = function ()
    local ucolors = require "catppuccin.utils.colors"
    local latte = require("catppuccin.palettes").get_palette "latte"
    local frappe = require("catppuccin.palettes").get_palette "frappe"
    local macchiato = require("catppuccin.palettes").get_palette "macchiato"
    local mocha = require("catppuccin.palettes").get_palette "mocha"

    vim.g.catppuccin_flavour = "frappe"
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
}

local kanagawa = {
  "rebelot/kanagawa.nvim",
  event = 'VeryLazy',
  config = function ()
    require('kanagawa').setup()
    vim.cmd [[ colorscheme kanagawa ]]
  end
}

local flipped = {
  "glepnir/flipped.nvim",
  event = "VeryLazy",
  config = function ()
    vim.cmd [[ colorscheme flipped ]]
  end
}

local newpaper = {
  "yorik1984/newpaper.nvim",
  event = "VeryLazy",
  config = function ()
    require("newpaper").setup({
      style = "light",
      lualine_style = "light"
    })
  end
}

local abscs = {
  "Abstract-IDE/Abstract-cs",
  event = "VimEnter",
  config = function ()
    vim.cmd[[colorscheme abscs]]   
  end
}

local everforest = {
  "sainnhe/everforest",
  event = "VimEnter",
  config = function ()
    vim.cmd[[colorscheme everforest]]   
  end
}

local vscode_theme = {
  "askfiy/visual_studio_code",
  event = "VimEnter",
  priority = 100,
  config = function()
    require("visual_studio_code").setup({
      mode = "dark",
    })
  end,
}

return vscode_theme
