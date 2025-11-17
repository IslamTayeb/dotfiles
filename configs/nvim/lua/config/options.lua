-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Move nvim-tree to the right
vim.g.nvim_tree_side = "right"

-- Enable text wrapping
vim.opt.wrap = true
vim.opt.linebreak = true -- Break lines at word boundaries
vim.opt.showbreak = "↪ " -- Optional: show line break indicator

-- Disable netrw (vim's built-in file explorer)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.python3_host_prog = "/Library/Frameworks/Python.framework/Versions/3.13/bin/python3"

vim.g.autoformat = true
