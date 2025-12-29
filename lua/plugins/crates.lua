-- return {
--     'saecki/crates.nvim',
--     ft = {"toml"},
--     config = function ()
--         require("crates").setup {
--             completion = {
--                 cmp = {
--                     enabled = true
--                 },
--             },
--         }
--         require('cmp').setup.buffer({
--             sources = {{ name = "crates" }}
--         })
--     end
-- }
return {
    'saecki/crates.nvim',
    tag = 'stable',
    config = function ()
        require('crates').setup()
    end,
}
