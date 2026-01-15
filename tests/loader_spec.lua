---@diagnostic disable: undefined-field
describe("loader", function()
  local loader

  -- Get the fixtures directory path relative to test file
  local function get_fixtures_path()
    local source = debug.getinfo(1, "S").source:sub(2)
    local dir = vim.fn.fnamemodify(source, ":h")
    return dir .. "/fixtures"
  end

  before_each(function()
    -- Clear module cache to get fresh state
    package.loaded["telescope._extensions.blink_snippets.loader"] = nil
    loader = require("telescope._extensions.blink_snippets.loader")
    loader.clear_cache()
  end)

  describe("parse_package_json", function()
    it("should parse contributes.snippets from package.json", function()
      local fixtures_path = get_fixtures_path()
      local package_path = fixtures_path .. "/package.json"

      local snippets_info = loader.parse_package_json(package_path)

      assert.is_table(snippets_info)
      assert.equals(3, #snippets_info)

      -- Check lua entry
      local lua_entry = snippets_info[1]
      assert.is_table(lua_entry.language)
      assert.same({ "lua" }, lua_entry.language)
      assert.truthy(lua_entry.path:match("lua%.json$"))

      -- Check multi-language entry (js-ts)
      local js_entry = snippets_info[3]
      assert.same({ "javascript", "typescript" }, js_entry.language)
    end)

    it("should return empty table for non-existent file", function()
      local snippets_info = loader.parse_package_json("/non/existent/path.json")
      assert.is_table(snippets_info)
      assert.equals(0, #snippets_info)
    end)

    it("should return empty table for invalid JSON", function()
      -- Create a temporary invalid JSON file
      local tmp_path = vim.fn.tempname()
      local f = io.open(tmp_path, "w")
      f:write("{ invalid json }")
      f:close()

      local snippets_info = loader.parse_package_json(tmp_path)
      assert.is_table(snippets_info)
      assert.equals(0, #snippets_info)

      os.remove(tmp_path)
    end)

    it("should return empty table for package.json without contributes.snippets", function()
      local tmp_path = vim.fn.tempname()
      local f = io.open(tmp_path, "w")
      f:write('{"name": "no-snippets"}')
      f:close()

      local snippets_info = loader.parse_package_json(tmp_path)
      assert.is_table(snippets_info)
      assert.equals(0, #snippets_info)

      os.remove(tmp_path)
    end)
  end)

  describe("parse_snippet_file", function()
    it("should parse VSCode snippet JSON format", function()
      local fixtures_path = get_fixtures_path()
      local snippet_path = fixtures_path .. "/snippets/lua.json"

      local snippets = loader.parse_snippet_file(snippet_path, { "lua" })

      assert.is_table(snippets)
      assert.equals(3, #snippets)

      -- Find the "For Loop" snippet
      local for_snippet
      for _, s in ipairs(snippets) do
        if s.name == "For Loop" then
          for_snippet = s
          break
        end
      end

      assert.is_not_nil(for_snippet)
      assert.same({ "for", "fori" }, for_snippet.prefix)
      assert.equals("Numeric for loop", for_snippet.description)
      assert.same({ "lua" }, for_snippet.filetypes)
      -- Body should be joined with newlines
      assert.truthy(for_snippet.body:match("for %$"))
    end)

    it("should handle string prefix (not array)", function()
      local fixtures_path = get_fixtures_path()
      local snippet_path = fixtures_path .. "/snippets/lua.json"

      local snippets = loader.parse_snippet_file(snippet_path, { "lua" })

      -- Find the "Function" snippet which has string prefix
      local fn_snippet
      for _, s in ipairs(snippets) do
        if s.name == "Function" then
          fn_snippet = s
          break
        end
      end

      assert.is_not_nil(fn_snippet)
      assert.same({ "fn" }, fn_snippet.prefix)
    end)

    it("should handle string body (not array)", function()
      local fixtures_path = get_fixtures_path()
      local snippet_path = fixtures_path .. "/snippets/lua.json"

      local snippets = loader.parse_snippet_file(snippet_path, { "lua" })

      -- Find "Local Variable" which has string body
      local lv_snippet
      for _, s in ipairs(snippets) do
        if s.name == "Local Variable" then
          lv_snippet = s
          break
        end
      end

      assert.is_not_nil(lv_snippet)
      assert.equals("local ${1:name} = ${2:value}", lv_snippet.body)
    end)

    it("should return empty table for non-existent file", function()
      local snippets = loader.parse_snippet_file("/non/existent.json", { "lua" })
      assert.is_table(snippets)
      assert.equals(0, #snippets)
    end)
  end)

  describe("load_snippets", function()
    it("should load all snippets from a directory with package.json", function()
      local fixtures_path = get_fixtures_path()

      local snippets = loader.load_snippets({ fixtures_path })

      -- Should have snippets from lua, python, and js-ts files
      assert.is_table(snippets)
      assert.is_true(#snippets > 0)

      -- Count snippets per filetype
      local lua_count = 0
      local python_count = 0
      local js_count = 0

      for _, s in ipairs(snippets) do
        for _, ft in ipairs(s.filetypes) do
          if ft == "lua" then
            lua_count = lua_count + 1
          elseif ft == "python" then
            python_count = python_count + 1
          elseif ft == "javascript" then
            js_count = js_count + 1
          end
        end
      end

      assert.equals(3, lua_count) -- for, fn, lv
      assert.equals(2, python_count) -- def, class
      assert.equals(2, js_count) -- cl, af (also in typescript)
    end)

    it("should cache snippets and not re-parse on second call", function()
      local fixtures_path = get_fixtures_path()

      -- First call
      local snippets1 = loader.load_snippets({ fixtures_path })
      -- Second call should return cached
      local snippets2 = loader.load_snippets({ fixtures_path })

      -- Should be the same table reference (cached)
      assert.equals(snippets1, snippets2)
    end)

    it("should clear cache when clear_cache is called", function()
      local fixtures_path = get_fixtures_path()

      local snippets1 = loader.load_snippets({ fixtures_path })
      loader.clear_cache()
      local snippets2 = loader.load_snippets({ fixtures_path })

      -- Should be different table references after cache clear
      assert.is_not.equals(snippets1, snippets2)
      -- But same content
      assert.equals(#snippets1, #snippets2)
    end)
  end)

  describe("get_snippets_for_filetype", function()
    it("should filter snippets by filetype", function()
      local fixtures_path = get_fixtures_path()

      local lua_snippets = loader.get_snippets_for_filetype("lua", { fixtures_path })

      assert.is_table(lua_snippets)
      assert.equals(3, #lua_snippets)

      for _, s in ipairs(lua_snippets) do
        assert.is_true(vim.tbl_contains(s.filetypes, "lua"))
      end
    end)

    it("should return empty table for unknown filetype", function()
      local fixtures_path = get_fixtures_path()

      local snippets = loader.get_snippets_for_filetype("rust", { fixtures_path })

      assert.is_table(snippets)
      assert.equals(0, #snippets)
    end)

    it("should support filetype aliases", function()
      local fixtures_path = get_fixtures_path()

      -- javascriptreact should include javascript snippets
      local aliases = {
        javascriptreact = { "javascript" },
      }

      local snippets = loader.get_snippets_for_filetype("javascriptreact", { fixtures_path }, aliases)

      assert.is_table(snippets)
      assert.equals(2, #snippets) -- cl and af from js-ts.json
    end)

    it("should return all snippets when filetype is 'all'", function()
      local fixtures_path = get_fixtures_path()

      local all_snippets = loader.get_snippets_for_filetype("all", { fixtures_path })

      assert.is_table(all_snippets)
      -- lua: 3, python: 2, js-ts: 2 = 7 total
      assert.equals(7, #all_snippets)
    end)
  end)

  describe("snippet structure", function()
    it("should have all required fields", function()
      local fixtures_path = get_fixtures_path()

      local snippets = loader.load_snippets({ fixtures_path })

      for _, s in ipairs(snippets) do
        assert.is_string(s.name, "snippet should have name")
        assert.is_table(s.prefix, "snippet should have prefix array")
        assert.is_true(#s.prefix > 0, "prefix should not be empty")
        assert.is_string(s.body, "snippet should have body")
        assert.is_table(s.filetypes, "snippet should have filetypes")
        -- description is optional but should be string if present
        if s.description then
          assert.is_string(s.description)
        end
      end
    end)
  end)
end)
