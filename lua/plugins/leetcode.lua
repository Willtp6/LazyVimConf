local leetcode_root = vim.fn.expand("~/Developer/playground/leetcode")

-- one folder per language; rust/ is a Cargo project with solutions in rust/src
local lang_dirs = {
  rust = leetcode_root .. "/rust/src",
  c = leetcode_root .. "/c",
}
local cargo_toml = leetcode_root .. "/rust/Cargo.toml"

-- pick per launch with `LEET_LANG=c nvim leetcode.nvim`, or `:LeetLang` inside nvim
local default_lang = lang_dirs[vim.env.LEET_LANG or ""] and vim.env.LEET_LANG or "rust"

-- leetcode.nvim saves everything in one `storage.home`; route each question to
-- its language's folder instead, also when switching languages mid-session.
local function use_lang_dirs()
  local Question = require("leetcode-ui.question")
  if Question._lang_dirs then
    return
  end
  Question._lang_dirs = true

  local Path = require("plenary.path")
  local config = require("leetcode.config")
  local path = Question.path

  function Question:path()
    local dir = lang_dirs[self.lang]
    if not dir then
      return path(self)
    end
    vim.fn.mkdir(dir, "p")
    local home = config.storage.home
    config.storage.home = Path:new(dir)
    local ok, file, existed = pcall(path, self)
    config.storage.home = home
    if not ok then
      error(file, 0)
    end
    return file, existed
  end
end

-- LeetCode ships helper types (TreeNode, ListNode, Node, ...) commented out
-- inside the @leet section: Rust as `// ...` lines, C as a `/** ... */` block.
-- Returns the block starting at line `i` (first, last, uncommented lines), if any.
local function definition_at(lines, i, last)
  if lines[i]:match("^%s*// Definition for") then
    local j = i
    while j < last and lines[j + 1]:match("^%s*//") and not lines[j + 1]:match("^%s*// Definition for") do
      j = j + 1
    end
    local defs = { lines[i] }
    for k = i + 1, j do
      table.insert(defs, (lines[k]:gsub("^(%s*)// ?", "%1")))
    end
    return i, j, defs
  end

  if lines[i]:match("^%s*/%*%*%s*$") and i < last and lines[i + 1]:match("^%s*%*%s*Definition for") then
    local j = i + 2
    while j <= last and not lines[j]:match("%*/") do
      j = j + 1
    end
    if j > last then
      return
    end
    local defs = { (lines[i + 1]:gsub("^%s*%*%s*", "// ")) }
    for k = i + 2, j - 1 do
      table.insert(defs, (lines[k]:gsub("^%s*%* ?", "")))
    end
    return i, j, defs
  end
end

-- Uncomment those definitions and move them above `@leet start` so the file
-- compiles locally, while the submitted section stays untouched.
local function hoist_definitions(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local start_i, end_i
  for i, line in ipairs(lines) do
    if not start_i and line:match("^%s*// @leet start") then
      start_i = i
    elseif start_i and line:match("^%s*// @leet end") then
      end_i = i
      break
    end
  end
  if not (start_i and end_i) then
    return
  end

  local blocks, defs = {}, {}
  local i = start_i + 1
  while i < end_i do
    local first, last, block = definition_at(lines, i, end_i - 1)
    if first then
      table.insert(blocks, { first, last })
      vim.list_extend(defs, block)
      i = last + 1
    else
      i = i + 1
    end
  end
  if #blocks == 0 then
    return
  end
  table.insert(defs, "")

  for b = #blocks, 1, -1 do
    vim.api.nvim_buf_set_lines(bufnr, blocks[b][1] - 1, blocks[b][2], false, {})
  end
  vim.api.nvim_buf_set_lines(bufnr, start_i - 1, start_i - 1, false, defs)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("silent! write")
  end)
end

return {
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",

    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- renders problem images in the description panel (Ghostty speaks the kitty protocol)
      -- requires ImageMagick: `brew install imagemagick`
      {
        "3rd/image.nvim",
        build = false,
        opts = {
          backend = "kitty",
          processor = "magick_cli",
          -- only used by leetcode.nvim; markdown rendering is left to markview
          integrations = {
            markdown = { enabled = false },
            asciidoc = { enabled = false },
            neorg = { enabled = false },
            rst = { enabled = false },
            typst = { enabled = false },
          },
        },
      },
    },

    opts = {
      lang = default_lang,
      image_support = true,
      storage = {
        home = lang_dirs[default_lang],
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
        -- LeetCode's C judge includes these implicitly; add them so clangd agrees
        c = {
          before = {
            "#include <limits.h>",
            "#include <math.h>",
            "#include <stdbool.h>",
            "#include <stdint.h>",
            "#include <stdio.h>",
            "#include <stdlib.h>",
            "#include <string.h>",
          },
        },
      },
      hooks = {
        ["enter"] = { use_lang_dirs },
        ["question_enter"] = {
          function(question)
            if question.lang ~= "rust" and question.lang ~= "c" then
              return
            end

            hoist_definitions(question.bufnr)

            if question.lang ~= "rust" then
              return
            end

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

            local file = io.open(cargo_toml, "w")

            if file then
              file:write(content:format(question.q.frontend_id, question:path()))
              file:close()
            end
          end,
        },
      },
    },

    config = function(_, opts)
      -- leetcode.nvim only creates the last component of storage.home
      vim.fn.mkdir(opts.storage.home, "p")
      require("leetcode").setup(opts)

      local langs = vim.tbl_keys(lang_dirs)
      table.sort(langs, function(a, b)
        return a == "rust" or (b ~= "rust" and a < b)
      end)

      -- choose the language, then open (or return to) leetcode
      local function start_with(lang)
        if not lang_dirs[lang] then
          return vim.notify("LeetCode language must be one of: " .. table.concat(langs, ", "), vim.log.levels.ERROR)
        end
        vim.fn.mkdir(lang_dirs[lang], "p")
        local config = require("leetcode.config")
        config.user.lang = lang -- read when :Leet starts
        config.user.storage.home = lang_dirs[lang]
        config.lang = lang -- used by questions opened from now on
        vim.cmd("Leet")
      end

      vim.api.nvim_create_user_command("LeetLang", function(args)
        if args.args ~= "" then
          return start_with(args.args)
        end
        vim.ui.select(langs, { prompt = "LeetCode language" }, function(choice)
          if choice then
            start_with(choice)
          end
        end)
      end, {
        nargs = "?",
        complete = function()
          return langs
        end,
        desc = "Choose LeetCode language and open leetcode.nvim",
      })
    end,
  },
}
