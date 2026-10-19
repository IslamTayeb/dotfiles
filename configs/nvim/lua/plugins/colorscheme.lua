return {
  {
    "rebelot/kanagawa.nvim",
    opts = {
      -- One flat background everywhere (Ghostty's #181616): no lighter gutter strip,
      -- no darker float/sidebar panels, subtle borders.
      colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
      overrides = function(colors)
        local ui = colors.theme.ui
        local flat = { bg = ui.bg }
        local border = { fg = "#393836", bg = ui.bg }
        return {
          NormalFloat = flat,
          FloatBorder = border,
          FloatTitle = { fg = ui.fg_dim, bg = ui.bg, bold = true },
          FloatFooter = { fg = ui.fg_dim, bg = ui.bg },
          WinSeparator = { fg = "#282727", bg = "none" },
          SnacksPicker = flat,
          SnacksPickerBorder = border,
          SnacksPickerList = flat,
          SnacksPickerInput = flat,
          SnacksPickerInputBorder = border,
          SnacksPickerPreview = flat,
          SnacksPickerPreviewBorder = border,
          SnacksPickerBox = flat,
          SnacksPickerBoxBorder = border,
          SnacksPickerTitle = { fg = ui.fg_dim, bg = ui.bg, bold = true },
        }
      end,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "kanagawa-dragon" },
  },
}
