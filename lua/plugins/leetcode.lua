return {
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",

    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },

    opts = {
      lang = "rust",
      storage = {
        home = vim.fn.expand("~/Developer/playground/leetcode"),
        cache = vim.fn.stdpath("cache") .. "/leetcode",
      },
      plugins = {
        non_standalone = false,
      },
      description = {
        position = "left",
        width = "35%",
        show_status = true,
      },
      editor = {
        reset_previous_code = false,
      },
      injector = {
        rust = {
          before = {
            "#![allow(dead_code)]",
            "pub struct Solution;",
          },
        },
      },
      hooks = {
        ["question_enter"] = {
          function(question)
            if question.lang ~= "rust" then
              return
            end

            local config = require("leetcode.config")
            local cargo_path = config.user.storage.home .. "/Cargo.toml"

            local content = [[
[package]
name = "leetcode"
version = "0.1.0"
edition = "2024"

[lib]
name = "leetcode_%s"
path = "%s"

[dependencies]
]]

            local file = io.open(cargo_path, "w")

            if file then
              file:write(content:format(question.q.frontend_id, question:path()))
              file:close()
            end
          end,
        },
      },
    },
  },
}
