return {
  "windwp/windline.nvim",
  -- event = "BufRead",
  priority = 1,
  config = function()
    require('wlsample.bubble')
  end
}
