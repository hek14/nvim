local override_hl = function ()
  vim.api.nvim_set_hl(0,'Visual',{bg = '#36497d', bold = true})
  vim.api.nvim_set_hl(0,'MatchParen',{bg = '#264f78', bold = true})
  vim.cmd([[
  " hi clear CursorLine
  hi! LspReferenceWrite guibg=#264f78 gui=bold
  hi! LspReferenceRead guibg=#39424c
  hi! LspReferenceText guibg=#39424c
  hi! IndentLine guifg=#524f4f
  hi! link StatusLeft StatusLine
  hi! link StatusRight StatusLine
  hi! link StatusMid StatusLine
  hi! Gray guifg=#52504c
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
    override_hl()
  end
}

local vscode_theme = {
  "askfiy/visual_studio_code",
  init = function()
    vim.schedule(function ()
      require("visual_studio_code").setup({
        mode = "dark",
      })
      override_hl()
    end)
  end,
  -- priority = 100,
  config = function()
    vim.cmd([[colorscheme visual_studio_code]])
  end,
}

local material = {
  'marko-cerovac/material.nvim',
  init = function()
    vim.schedule(function ()
      vim.g.material_style = "palenight"
      vim.cmd 'colorscheme material'
      override_hl()
    end)
  end,
}

local paradox = {
  'nvimdev/paradox.vim',
  config = function()
    vim.cmd.colorscheme('paradox')
    override_hl()
  end
}

local srcery = {
  "srcery-colors/srcery-vim",
  event = "VeryLazy",
  config = function()
    vim.g.srcery_italic = 1
    vim.cmd.colorscheme('srcery')
    override_hl()
  end
}

local rose_pine = {
  'rose-pine/neovim', 
  name = 'rose-pine',
  event = "VeryLazy",
  config = function()
    vim.cmd.colorscheme('rose-pine')
  end
}

return srcery
