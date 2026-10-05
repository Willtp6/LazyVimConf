return {
  {
    "mrcjkb/rustaceanvim",

    opts = function(_, opts)
      opts.server = opts.server or {}

      opts.server.root_dir = function(fname)
        local leetcode_dir = vim.fn.expand("~/Developer/playground/leetcode")

        if fname:sub(1, #leetcode_dir) == leetcode_dir then
          return leetcode_dir
        end

        return vim.fs.root(fname, {
          "Cargo.toml",
          "rust-project.json",
          ".git",
        })
      end

      return opts
    end,
  },
}
