-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
-- Auto move file explorer right after opening
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "neo-tree", "NvimTree", "oil" },
  callback = function()
    vim.defer_fn(function()
      vim.cmd("wincmd L") -- Move current window to far right
    end, 50)
  end,
})
