---@diagnostic disable: undefined-field
describe("picker", function()
  local picker
  local config

  -- Get the fixtures directory path
  local function get_fixtures_path()
    local source = debug.getinfo(1, "S").source:sub(2)
    local dir = vim.fn.fnamemodify(source, ":h")
    return dir .. "/fixtures"
  end

  before_each(function()
    -- Clear module cache
    package.loaded["telescope._extensions.blink_snippets.picker"] = nil
    package.loaded["telescope._extensions.blink_snippets.config"] = nil
    package.loaded["telescope._extensions.blink_snippets.loader"] = nil

    picker = require("telescope._extensions.blink_snippets.picker")
    config = require("telescope._extensions.blink_snippets.config")

    -- Clear loader cache
    local loader = require("telescope._extensions.blink_snippets.loader")
    loader.clear_cache()

    -- Setup config with fixtures path only (no runtime snippets)
    config.setup({
      search_paths = { get_fixtures_path() },
      include_runtime = false,
    })
  end)

  describe("make_entry", function()
    it("should create entry with display, ordinal, and value", function()
      local snippet = {
        name = "For Loop",
        prefix = { "for", "fori" },
        body = "for ${1:i} = 1, 10 do\n\t$0\nend",
        description = "Numeric for loop",
        filetypes = { "lua" },
      }

      local entry = picker.make_entry(snippet)

      assert.is_not_nil(entry)
      assert.equals(snippet, entry.value)
      assert.is_string(entry.display)
      assert.is_string(entry.ordinal)

      -- Ordinal should include prefix and name for fuzzy matching
      assert.truthy(entry.ordinal:match("for"))
      assert.truthy(entry.ordinal:match("For Loop"))
    end)

    it("should handle snippets without description", function()
      local snippet = {
        name = "Test",
        prefix = { "test" },
        body = "test",
        filetypes = { "lua" },
      }

      local entry = picker.make_entry(snippet)

      assert.is_not_nil(entry)
      assert.is_string(entry.display)
    end)

    it("should show multiple prefixes separated by comma", function()
      local snippet = {
        name = "Test",
        prefix = { "t", "test", "tst" },
        body = "test",
        filetypes = { "lua" },
      }

      local entry = picker.make_entry(snippet)

      -- The display should contain all prefixes
      assert.truthy(entry.ordinal:match("t"))
      assert.truthy(entry.ordinal:match("test"))
      assert.truthy(entry.ordinal:match("tst"))
    end)
  end)

  describe("get_snippets", function()
    it("should return snippets for current filetype", function()
      -- Set buffer filetype to lua
      vim.bo.filetype = "lua"

      local snippets = picker.get_snippets({})

      assert.is_table(snippets)
      assert.equals(3, #snippets) -- lua has 3 snippets in fixtures
    end)

    it("should return all snippets when all_filetypes is true", function()
      local snippets = picker.get_snippets({ all_filetypes = true })

      assert.is_table(snippets)
      assert.equals(7, #snippets) -- all snippets in fixtures
    end)

    it("should respect filetype aliases", function()
      vim.bo.filetype = "javascriptreact"

      config.setup({
        search_paths = { get_fixtures_path() },
        include_runtime = false,
        filetype_aliases = {
          javascriptreact = { "javascript" },
        },
      })

      local snippets = picker.get_snippets({})

      assert.is_table(snippets)
      assert.equals(2, #snippets) -- javascript snippets
    end)
  end)

  describe("format_body_for_preview", function()
    it("should return body lines as table", function()
      local body = "line1\nline2\nline3"

      local lines = picker.format_body_for_preview(body)

      assert.is_table(lines)
      assert.equals(3, #lines)
      assert.equals("line1", lines[1])
      assert.equals("line2", lines[2])
      assert.equals("line3", lines[3])
    end)

    it("should handle single line body", function()
      local body = "single line"

      local lines = picker.format_body_for_preview(body)

      assert.is_table(lines)
      assert.equals(1, #lines)
      assert.equals("single line", lines[1])
    end)
  end)

  describe("insert_snippet", function()
    it("should call vim.snippet.expand with body", function()
      -- Create a mock for vim.snippet.expand
      local expand_called = false
      local expand_body = nil

      local original_expand = vim.snippet.expand
      vim.snippet.expand = function(body)
        expand_called = true
        expand_body = body
      end

      local snippet = {
        name = "Test",
        prefix = { "test" },
        body = "test snippet body",
        filetypes = { "lua" },
      }

      picker.insert_snippet(snippet)

      assert.is_true(expand_called)
      assert.equals("test snippet body", expand_body)

      -- Restore original
      vim.snippet.expand = original_expand
    end)
  end)
end)
