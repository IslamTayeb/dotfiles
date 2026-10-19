return {
  {
    "rebelot/kanagawa.nvim",
    opts = {
      -- Editor on Ghostty's #181616, side panels and pickers one shade darker,
      -- no lighter gutter strip, subtle borders.
      colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
      overrides = function(colors)
        local ui = colors.theme.ui
        local panel = "#0d0c0c"
        local flat = { bg = ui.bg }
        local border = { fg = "#393836", bg = ui.bg }
        local pflat = { bg = panel }
        local pborder = { fg = "#393836", bg = panel }
        local ptitle = { fg = ui.fg_dim, bg = panel, bold = true }
        return {
          NormalFloat = flat,
          FloatBorder = border,
          FloatTitle = { fg = ui.fg_dim, bg = ui.bg, bold = true },
          FloatFooter = { fg = ui.fg_dim, bg = ui.bg },
          WinSeparator = { fg = panel, bg = panel },
          -- Dragon inherits Wave's blue (#223249/#2d4f67) for menus and selection; use Dragon greys.
          Pmenu = { fg = ui.fg, bg = "#282727" },
          PmenuSel = { bg = "#393836", bold = true },
          PmenuSbar = { bg = "#282727" },
          PmenuThumb = { bg = "#625e5a" },
          Visual = { bg = "#625e5a" },
          -- Explorer sidebar, pickers and other snacks panels (terminal, lazygit)
          SnacksNormal = pflat,
          SnacksNormalNC = pflat,
          SnacksWinSeparator = { fg = panel, bg = panel },
          SnacksPicker = pflat,
          SnacksPickerBorder = pborder,
          SnacksPickerTitle = ptitle,
          SnacksPickerBox = pflat,
          SnacksPickerBoxBorder = pborder,
          SnacksPickerBoxTitle = ptitle,
          SnacksPickerList = pflat,
          SnacksPickerListBorder = pborder,
          SnacksPickerListCursorLine = { bg = "#282727" },
          SnacksPickerInput = pflat,
          SnacksPickerInputBorder = pborder,
          SnacksPickerInputTitle = ptitle,
          SnacksPickerPreview = pflat,
          SnacksPickerPreviewBorder = pborder,
          SnacksPickerPreviewTitle = ptitle,
        }
      end,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "kanagawa-dragon" },
  },
}
