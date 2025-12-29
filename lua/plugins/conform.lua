return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      c = { "clang_format" },
      cpp = { "clang_format" },
      h = { "clang_format" },
      rust = {"rustfmt"},
    },
  },
}

