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

-- LeetCode ships helper types (TreeNode, ListNode, Node, ...) as a commented
-- "Definition for ..." block inside the @leet section. Uncomment it and move it
-- above `@leet start` so it compiles locally but is never submitted.
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

  local def_start
  for i = start_i + 1, end_i - 1 do
    if lines[i]:match("^%s*// Definition for") then
      def_start = i
      break
    end
  end
  if not def_start then
    return
  end

  local def_end = def_start
  while def_end + 1 < end_i and lines[def_end + 1]:match("^%s*//") do
    def_end = def_end + 1
  end

  local defs = { lines[def_start] }
  for i = def_start + 1, def_end do
    table.insert(defs, (lines[i]:gsub("^(%s*)// ?", "%1")))
  end
  table.insert(defs, "")

  vim.api.nvim_buf_set_lines(bufnr, def_start - 1, def_end, false, {})
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
      },
      hooks = {
        ["enter"] = { use_lang_dirs },
        ["question_enter"] = {
          function(question)
            if question.lang ~= "rust" then
              return
            end

            hoist_definitions(question.bufnr)

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
