return {
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "*", -- 对所有文件启用
      }, {
        RRGGBBAA = true,
        mode = "background",
      })
    end,
  },
}
