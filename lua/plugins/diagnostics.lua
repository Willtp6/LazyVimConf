-- Default virtual text runs off the right edge in narrow windows (e.g. next to
-- the leetcode description panel). tiny-inline-diagnostic wraps long messages
-- to fit the window instead.
return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    opts = {
      options = {
        -- show every diagnostic on the cursor line, not just the one under the cursor
        show_all_diags_on_cursorline = true,
        multilines = {
          enabled = true,
          -- errors stay visible on every line; warnings/hints only on the cursor line
          always_show = true,
          severity = { vim.diagnostic.severity.ERROR },
        },
        overflow = {
          mode = "wrap",
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = { diagnostics = { virtual_text = false } },
  },
}
