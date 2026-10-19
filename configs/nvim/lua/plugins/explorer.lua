return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- no dimmed backdrop behind pickers (made the screen look patchy)
        layout = { layout = { backdrop = false } },
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
