local hook = function ()
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
  " hi! WinSeparator guibg=#4d5461 ctermbg=238
  ]])
  -- NOTE: load plugins that rely on theme
  require("lazy").load({plugins = {"windline.nvim", "bufferline.nvim", "todo-comments.nvim"}})
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
    hook()
  end
}

local kanagawa = {
  "rebelot/kanagawa.nvim",
  event = 'VeryLazy',
  config = function ()
    require('kanagawa').setup()
    vim.cmd [[ colorscheme kanagawa ]]
    hook()
  end
}

local flipped = {
  "glepnir/flipped.nvim",
  event = "VeryLazy",
  config = function ()
    vim.cmd [[ colorscheme flipped ]]
    hook()
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
    hook()
  end
}

local abscs = {
  "Abstract-IDE/Abstract-cs",
  event = "VimEnter",
  config = function ()
    vim.cmd[[colorscheme abscs]]
    hook()
  end
}

local everforest = {
  "sainnhe/everforest",
  event = "VimEnter",
  config = function ()
    vim.cmd[[colorscheme everforest]]
    hook()
  end
}

local vscode = {
  "askfiy/visual_studio_code",
  init = function()
    vim.schedule(function ()
      require("visual_studio_code").setup({
        mode = "dark",
      })
      hook()
    end)
  end,
  -- priority = 100,
  config = function ()
    vim.cmd([[colorscheme visual_studio_code]])
    hook()
  end,
}

local material = {
  'marko-cerovac/material.nvim',
  init = function()
    vim.schedule(function ()
      vim.g.material_style = "palenight"
      vim.cmd 'colorscheme material'
      hook()
    end)
  end,
}

local srcery = {
  "srcery-colors/srcery-vim",
  event = "VeryLazy",
  config = function ()
    vim.g.srcery_italic = 1
    vim.cmd.colorscheme('srcery')
    hook()
  end
}

local rose_pine = {
  'rose-pine/neovim',
  name = 'rose-pine',
  event = "VeryLazy",
  config = function ()
    vim.cmd.colorscheme('rose-pine')
    hook()
  end
}

local tokyonight = {
  "folke/tokyonight.nvim",
  name = "tokyonight",
  priority = 1000,
  event = "VeryLazy",
  config = function ()
    local status_ok, tokyonight = pcall(require, "tokyonight")
    if not status_ok then
      return
    end
    tokyonight.setup({})
    tokyonight.load()
    hook()
  end,
}

local darkplus = {
  "LunarVim/darkplus.nvim",
  event = 'VeryLazy',
  priority = 999,
  config = function ()
    vim.cmd("colorscheme darkplus")
    hook()
  end
}

return vscode
