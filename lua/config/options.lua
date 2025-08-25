-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.autoformat = false
-- vim.g.neovide_cursor_vfx_mode = "pixeldust"

local opt = vim.opt

opt.spell = false
opt.wrap = true
opt.relativenumber = false
opt.guifont = { "UbuntuMono Nert Font Mono", "Lantinghei TC", ":h16" }
opt.list = true
opt.swapfile = false

-- opt.relativenumber = true
vim.o.completeopt = "menu,menuone,noinsert,noselect"

