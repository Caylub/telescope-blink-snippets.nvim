---@diagnostic disable: undefined-field
describe("config", function()
  local config

  before_each(function()
    -- Clear module cache
    package.loaded["telescope._extensions.blink_snippets.config"] = nil
    config = require("telescope._extensions.blink_snippets.config")
  end)

  describe("defaults", function()
    it("should have default search_paths as empty table", function()
      local defaults = config.defaults
      assert.is_table(defaults.search_paths)
      assert.equals(0, #defaults.search_paths)
    end)

    it("should have all_filetypes default to false", function()
      assert.is_false(config.defaults.all_filetypes)
    end)

    it("should have filetype_aliases as empty table", function()
      local defaults = config.defaults
      assert.is_table(defaults.filetype_aliases)
    end)
  end)

  describe("setup", function()
    it("should merge user options with defaults", function()
      config.setup({
        search_paths = { "/custom/path" },
        all_filetypes = true,
      })

      local opts = config.get()
      assert.same({ "/custom/path" }, opts.search_paths)
      assert.is_true(opts.all_filetypes)
      assert.is_table(opts.filetype_aliases)
    end)

    it("should preserve defaults for unset options", function()
      config.setup({
        all_filetypes = true,
      })

      local opts = config.get()
      assert.is_true(opts.all_filetypes)
      assert.is_table(opts.search_paths)
      assert.equals(0, #opts.search_paths)
    end)

    it("should deep merge filetype_aliases", function()
      config.setup({
        filetype_aliases = {
          javascriptreact = { "javascript" },
          typescriptreact = { "typescript" },
        },
      })

      local opts = config.get()
      assert.same({ "javascript" }, opts.filetype_aliases.javascriptreact)
      assert.same({ "typescript" }, opts.filetype_aliases.typescriptreact)
    end)
  end)

  describe("get", function()
    it("should return defaults if setup not called", function()
      local opts = config.get()
      assert.is_false(opts.all_filetypes)
      assert.is_table(opts.search_paths)
    end)

    it("should return copy not reference", function()
      local opts1 = config.get()
      local opts2 = config.get()

      -- Modifying one should not affect the other
      opts1.all_filetypes = true
      assert.is_false(opts2.all_filetypes)
    end)
  end)

  describe("get_search_paths", function()
    it("should include runtime snippet packages", function()
      -- This test verifies the function exists and returns a table
      -- Actual runtime paths depend on the environment
      local paths = config.get_search_paths()
      assert.is_table(paths)
    end)

    it("should include user-configured search_paths", function()
      config.setup({
        search_paths = { "/custom/snippets" },
      })

      local paths = config.get_search_paths()
      assert.is_table(paths)
      assert.is_true(vim.tbl_contains(paths, "/custom/snippets"))
    end)
  end)
end)
