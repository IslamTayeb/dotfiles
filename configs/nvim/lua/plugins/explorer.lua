return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            include = { ".env", ".env.*" },
            layout = { layout = { position = "right" } },
          },
        },
      },
    },
  },
}
