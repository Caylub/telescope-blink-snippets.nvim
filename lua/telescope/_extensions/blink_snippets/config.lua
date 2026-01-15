--- Configuration for telescope-blink-snippets
--- @module telescope._extensions.blink_snippets.config

local M = {}

---@class BlinkSnippetsConfig
---@field search_paths string[] Additional directories to search for snippets
---@field all_filetypes boolean Show all filetypes by default
---@field filetype_aliases table<string, string[]> Map filetypes to additional filetypes
---@field include_runtime boolean Include runtime snippet packages (default: true)

--- Default configuration
---@type BlinkSnippetsConfig
M.defaults = {
  search_paths = {},
  all_filetypes = false,
  filetype_aliases = {},
  include_runtime = true,
}

--- Current configuration (initialized to defaults)
---@type BlinkSnippetsConfig
local current_config = vim.deepcopy(M.defaults)

--- Setup the configuration with user options
---@param opts? BlinkSnippetsConfig User configuration options
function M.setup(opts)
  opts = opts or {}
  current_config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
end

--- Get the current configuration
---@return BlinkSnippetsConfig Copy of current config
function M.get()
  return vim.deepcopy(current_config)
end

--- Find snippet packages in the Neovim runtime
---@return string[] Array of paths containing package.json with snippets
local function find_runtime_snippet_packages()
  local paths = {}

  -- Find all package.json files in runtimepath
  local runtime_packages = vim.api.nvim_get_runtime_file("package.json", true)

  for _, package_path in ipairs(runtime_packages) do
    -- Read and check if it has contributes.snippets
    local f = io.open(package_path, "r")
    if f then
      local content = f:read("*a")
      f:close()

      local ok, data = pcall(vim.json.decode, content)
      if ok and data and data.contributes and data.contributes.snippets then
        -- Add the directory containing this package.json
        local dir = vim.fn.fnamemodify(package_path, ":h")
        table.insert(paths, dir)
      end
    end
  end

  return paths
end

--- Get all search paths (runtime + user configured)
---@return string[] Array of all paths to search
function M.get_search_paths()
  local paths = {}

  -- Add runtime snippet packages (e.g., friendly-snippets)
  if current_config.include_runtime then
    local runtime_paths = find_runtime_snippet_packages()
    for _, path in ipairs(runtime_paths) do
      table.insert(paths, path)
    end
  end

  -- Add user-configured paths
  for _, path in ipairs(current_config.search_paths) do
    table.insert(paths, path)
  end

  return paths
end

return M
