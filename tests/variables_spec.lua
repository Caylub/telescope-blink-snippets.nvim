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
  end)
end)
