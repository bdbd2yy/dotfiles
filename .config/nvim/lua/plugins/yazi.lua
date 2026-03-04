return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = {
      "folke/snacks.nvim",
    },
    keys = {
      {
        "<leader>fy",
        "<cmd>Yazi<cr>",
        desc = "Open Yazi",
      },
    },
  },
}
