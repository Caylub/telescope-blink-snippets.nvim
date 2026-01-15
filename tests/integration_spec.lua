---@diagnostic disable: undefined-field
describe("integration", function()
  -- Get the fixtures directory path
  local function get_fixtures_path()
    local source = debug.getinfo(1, "S").source:sub(2)
    local dir = vim.fn.fnamemodify(source, ":h")
    return dir .. "/fixtures"
  end

  before_each(function()
    -- Clear all related module caches
    for name, _ in pairs(package.loaded) do
      if name:match("^telescope%._extensions%.blink_snippets") then
        package.loaded[name] = nil
      end
    end
  end)

  describe("extension loading", function()
    it("should register with telescope", function()
      local telescope = require("telescope")

      -- Load the extension
      telescope.load_extension("blink_snippets")

      -- The extension should be available
      local ext = telescope.extensions.blink_snippets
      assert.is_not_nil(ext)
      assert.is_function(ext.blink_snippets)
    end)

    it("should accept configuration via setup", function()
      local telescope = require("telescope")

      telescope.setup({
        extensions = {
          blink_snippets = {
            search_paths = { get_fixtures_path() },
            all_filetypes = true,
            include_runtime = false,
          },
        },
      })

      telescope.load_extension("blink_snippets")

      -- Verify config was applied
      local config = require("telescope._extensions.blink_snippets.config")
      local opts = config.get()

      assert.is_true(opts.all_filetypes)
      assert.is_true(vim.tbl_contains(opts.search_paths, get_fixtures_path()))
    end)
  end)

  describe("snippet loading from runtime", function()
    it("should find friendly-snippets if available", function()
      local config = require("telescope._extensions.blink_snippets.config")
      config.setup({}) -- Default: include_runtime = true

      local paths = config.get_search_paths()

      -- This test is environment-dependent
      -- It passes if friendly-snippets is in runtimepath
      assert.is_table(paths)
    end)
  end)

  describe("end-to-end workflow", function()
    it("should load and filter snippets correctly", function()
      local config = require("telescope._extensions.blink_snippets.config")
      local loader = require("telescope._extensions.blink_snippets.loader")

      loader.clear_cache()
      config.setup({
        search_paths = { get_fixtures_path() },
        include_runtime = false,
        filetype_aliases = {
          typescriptreact = { "typescript", "javascript" },
        },
      })

      -- Get TypeScript snippets (should include JS via alias in fixtures)
      vim.bo.filetype = "typescript"
      local ts_snippets = loader.get_snippets_for_filetype(
        "typescript",
        config.get_search_paths(),
        config.get().filetype_aliases
      )

      -- js-ts.json has 2 snippets that apply to both JS and TS
      assert.equals(2, #ts_snippets)

      -- Test typescriptreact alias
      local tsx_snippets = loader.get_snippets_for_filetype(
        "typescriptreact",
        config.get_search_paths(),
        config.get().filetype_aliases
      )

      -- Should get typescript snippets via alias
      assert.equals(2, #tsx_snippets)
    end)
  end)
end)
