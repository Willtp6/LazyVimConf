-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jk", "<ESC>", { silent = true })
-- for leetcode plugin
vim.keymap.set("n", "<leader>ll", "<cmd>Leet list<cr>", {
    desc = "LeetCode List",
})

vim.keymap.set("n", "<leader>lt", "<cmd>Leet tabs<cr>", {
    desc = "LeetCode Tabs",
})

vim.keymap.set("n", "<leader>lr", "<cmd>Leet run<cr>", {
    desc = "LeetCode Run",
})

vim.keymap.set("n", "<leader>ls", "<cmd>Leet submit<cr>", {
    desc = "LeetCode Submit",
})
