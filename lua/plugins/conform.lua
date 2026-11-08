local default_clang_format = vim.fn.stdpath("config") .. "/.clang-format"

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        h = { "clang_format" },
        rust = { "rustfmt" },
      },
      formatters = {
        clang_format = {
          -- prefer the project's own .clang-format; otherwise use the global default in this config
          prepend_args = function(_, ctx)
            local project = vim.fs.find({ ".clang-format", "_clang-format" }, { upward = true, path = ctx.dirname })
            if project[1] then
              return {}
            end
            return { "--style=file:" .. default_clang_format }
          end,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "clang-format" } },
  },
}
