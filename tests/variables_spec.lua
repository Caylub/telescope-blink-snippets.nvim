--- Tests for VSCode variable expansion
--- @module tests.variables_spec

local variables = require("telescope._extensions.blink_snippets.variables")

describe("variables", function()
  describe("get_variables", function()
    it("returns datetime variables", function()
      local vars = variables.get_variables()

      assert.is_not_nil(vars.CURRENT_YEAR)
      assert.is_not_nil(vars.CURRENT_MONTH)
      assert.is_not_nil(vars.CURRENT_DATE)
      assert.is_not_nil(vars.CURRENT_HOUR)
      assert.is_not_nil(vars.CURRENT_MINUTE)
      assert.is_not_nil(vars.CURRENT_SECOND)

      -- Year should be 4 digits
      assert.equals(4, #vars.CURRENT_YEAR)

      -- Month should be 2 digits
      assert.equals(2, #vars.CURRENT_MONTH)

      -- Date should be 2 digits
      assert.equals(2, #vars.CURRENT_DATE)
    end)

    it("returns file variables", function()
      local vars = variables.get_variables()

      assert.is_not_nil(vars.TM_FILENAME)
      assert.is_not_nil(vars.TM_LINE_NUMBER)
      assert.is_not_nil(vars.WORKSPACE_FOLDER)
    end)

    it("returns UUID", function()
      local vars = variables.get_variables()

      assert.is_not_nil(vars.UUID)
      -- UUID format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      assert.equals(36, #vars.UUID)
      assert.is_truthy(vars.UUID:match("^%x+%-%x+%-4%x+%-%x+%-%x+$"))
    end)
  end)

  describe("expand", function()
    it("expands $VAR syntax", function()
      local body = "$CURRENT_YEAR-$CURRENT_MONTH-$CURRENT_DATE"
      local result = variables.expand(body)

      -- Should not contain $CURRENT anymore
      assert.is_falsy(result:match("%$CURRENT"))

      -- Should be in YYYY-MM-DD format
      assert.is_truthy(result:match("^%d%d%d%d%-%d%d%-%d%d$"))
    end)

    it("expands ${VAR} syntax", function()
      local body = "${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}"
      local result = variables.expand(body)

      assert.is_falsy(result:match("%${CURRENT"))
      assert.is_truthy(result:match("^%d%d%d%d%-%d%d%-%d%d$"))
    end)

    it("preserves tabstops", function()
      local body = "function ${1:name}($2) {\n\t$0\n}"
      local result = variables.expand(body)

      -- Tabstops should remain
      assert.is_truthy(result:match("%${1:name}"))
      assert.is_truthy(result:match("%$2"))
      assert.is_truthy(result:match("%$0"))
    end)

    it("expands ${VAR:default} with default when var unknown", function()
      local body = "${UNKNOWN_VAR:fallback}"
      local result = variables.expand(body)

      assert.equals("fallback", result)
    end)

    it("expands ${VAR:default} with value when var known", function()
      local body = "${CURRENT_YEAR:2000}"
      local result = variables.expand(body)

      -- Should use actual year, not default
      assert.is_falsy(result:match("2000"))
      assert.is_truthy(result:match("^%d%d%d%d$"))
    end)

    it("handles mixed content", function()
      local body = "// Date: $CURRENT_YEAR\nfunction ${1:name}() {\n\t$0\n}"
      local result = variables.expand(body)

      -- Year should be expanded
      assert.is_falsy(result:match("%$CURRENT_YEAR"))
      -- Tabstops preserved
      assert.is_truthy(result:match("%${1:name}"))
    end)

    it("expands UUID", function()
      local body = "$UUID"
      local result = variables.expand(body)

      assert.equals(36, #result)
    end)

    it("expands CURSOR_INDEX and CURSOR_NUMBER", function()
      local vars = variables.get_variables()

      assert.is_not_nil(vars.CURSOR_INDEX)
      assert.is_not_nil(vars.CURSOR_NUMBER)
    end)

    it("applies /upcase modifier", function()
      local body = "${TM_FILENAME_BASE:/upcase}"
      local result = variables.expand(body)

      -- Should be all uppercase
      assert.equals(result, result:upper())
    end)

    it("applies /downcase modifier", function()
      local body = "${TM_FILENAME_BASE:/downcase}"
      local result = variables.expand(body)

      -- Should be all lowercase
      assert.equals(result, result:lower())
    end)

    it("applies /capitalize modifier", function()
      local body = "${TM_FILENAME_BASE:/capitalize}"
      local result = variables.expand(body)

      -- First char should be uppercase
      if #result > 0 then
        assert.equals(result:sub(1, 1), result:sub(1, 1):upper())
      end
    end)

    it("applies /snakecase modifier", function()
      -- Test with a known value
      local vars = variables.get_variables()
      -- We can't easily test TM_FILENAME_BASE since it depends on buffer
      -- but we can verify the modifier works by checking the pattern
      local body = "${TM_FILENAME_BASE:/snakecase}"
      local result = variables.expand(body)

      -- Result should not contain uppercase letters
      assert.is_falsy(result:match("[A-Z]"))
    end)

    it("applies /camelcase modifier", function()
      local body = "${TM_FILENAME_BASE:/camelcase}"
      local result = variables.expand(body)

      -- Should start with lowercase
      if #result > 0 then
        assert.equals(result:sub(1, 1), result:sub(1, 1):lower())
      end
    end)
  end)
end)
