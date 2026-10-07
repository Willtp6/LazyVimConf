-- Cargo.toml lives in `leetcode_root`; solution files go one level deeper
local leetcode_root = vim.fn.expand("~/Developer/playground/leetcode")

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
    },

    opts = {
      lang = "rust",
      storage = {
        home = leetcode_root .. "/src",
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

            hoist_definitions(question.bufnr)

            local cargo_path = leetcode_root .. "/Cargo.toml"

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
