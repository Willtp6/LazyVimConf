-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
if vim.g.vscode then
else
-- require'lspconfig'.clangd.setup {
--     cmd = { "clangd", "--compile-commands-dir=" .. vim.fn.getcwd() },
--     root_dir = require('lspconfig.util').root_pattern('CMakeLists.txt', 'compile_commands.json', '.git')
-- }
end
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.colorcolumn = "121"
-- vim.opt.wrap = false
