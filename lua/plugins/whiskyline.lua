return { 
  "glepnir/whiskyline.nvim",
  enabled = false,
  event = "VeryLazy",
  config = function ()
    require("whiskyline").setup()
  end
}
