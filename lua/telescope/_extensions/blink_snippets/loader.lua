--- VSCode snippet loader for telescope-blink-snippets
--- @module telescope._extensions.blink_snippets.loader

local M = {}

---@class Snippet
---@field name string The snippet name (key from JSON)
---@field prefix string[] Array of trigger prefixes
---@field body string The snippet body (joined with newlines if array)
---@field description string? Optional description
---@field filetypes string[] Array of filetypes this snippet applies to

---@class SnippetFileInfo
---@field language string[] Array of languages this file applies to
---@field path string Absolute path to the snippet JSON file

--- Cache for loaded snippets
---@type Snippet[]|nil
local snippet_cache = nil

--- Cache key for invalidation
---@type string|nil
local cache_key = nil

--- Clear the snippet cache
function M.clear_cache()
  snippet_cache = nil
  cache_key = nil
end

--- Read and parse a JSON file
---@param path string Path to JSON file
---@return table|nil Parsed JSON or nil on error
local function read_json(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end

  local content = f:read("*a")
  f:close()

  local ok, result = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end

  return result
end

--- Parse package.json to extract snippet file information
---@param package_path string Path to package.json
---@return SnippetFileInfo[] Array of snippet file info
function M.parse_package_json(package_path)
  local data = read_json(package_path)
  if not data then
    return {}
  end

  local contributes = data.contributes
  if not contributes or not contributes.snippets then
    return {}
  end

  local base_dir = vim.fn.fnamemodify(package_path, ":h")
  local result = {}

  for _, snippet_entry in ipairs(contributes.snippets) do
    local language = snippet_entry.language
    local path = snippet_entry.path

    if language and path then
      -- Normalize language to array
      if type(language) == "string" then
        language = { language }
      end

      -- Resolve relative path
      local abs_path
      if path:sub(1, 2) == "./" then
        abs_path = base_dir .. "/" .. path:sub(3)
      elseif path:sub(1, 1) ~= "/" then
        abs_path = base_dir .. "/" .. path
      else
        abs_path = path
      end

      table.insert(result, {
        language = language,
        path = abs_path,
      })
    end
  end

  return result
end

--- Parse a VSCode snippet JSON file
---@param snippet_path string Path to the snippet JSON file
---@param filetypes string[] Filetypes this file applies to
---@return Snippet[] Array of parsed snippets
function M.parse_snippet_file(snippet_path, filetypes)
  local data = read_json(snippet_path)
  if not data then
    return {}
  end

  local result = {}

  for name, snippet_data in pairs(data) do
    local prefix = snippet_data.prefix
    local body = snippet_data.body
    local description = snippet_data.description

    -- Normalize prefix to array
    if type(prefix) == "string" then
      prefix = { prefix }
    end

    -- Normalize body to string (join array with newlines)
    if type(body) == "table" then
      body = table.concat(body, "\n")
    end

    if prefix and body then
      table.insert(result, {
        name = name,
        prefix = prefix,
        body = body,
        description = description,
        filetypes = filetypes,
      })
    end
  end

  return result
end

--- Find all package.json files in search paths
---@param search_paths string[] Paths to search
---@return string[] Array of package.json paths
local function find_package_files(search_paths)
  local package_files = {}

  for _, path in ipairs(search_paths) do
    local package_path = path .. "/package.json"
    if vim.fn.filereadable(package_path) == 1 then
      table.insert(package_files, package_path)
    end
  end

  return package_files
end

--- Generate a cache key from search paths
---@param search_paths string[]
---@return string
local function make_cache_key(search_paths)
  return table.concat(search_paths, ":")
end

--- Load all snippets from given search paths
---@param search_paths string[] Directories to search for package.json
---@return Snippet[] Array of all snippets
function M.load_snippets(search_paths)
  local key = make_cache_key(search_paths)

  -- Return cached if available and paths match
  if snippet_cache and cache_key == key then
    return snippet_cache
  end

  local snippets = {}
  local package_files = find_package_files(search_paths)

  for _, package_path in ipairs(package_files) do
    local snippet_files = M.parse_package_json(package_path)

    for _, file_info in ipairs(snippet_files) do
      local file_snippets = M.parse_snippet_file(file_info.path, file_info.language)
      for _, snippet in ipairs(file_snippets) do
        table.insert(snippets, snippet)
      end
    end
  end

  -- Cache the results
  snippet_cache = snippets
  cache_key = key

  return snippets
end

--- Get snippets filtered by filetype
---@param filetype string Filetype to filter by, or "all" for all snippets
---@param search_paths string[] Directories to search
---@param aliases? table<string, string[]> Filetype aliases
---@return Snippet[] Filtered array of snippets
function M.get_snippets_for_filetype(filetype, search_paths, aliases)
  local all_snippets = M.load_snippets(search_paths)

  -- Return all if filetype is "all"
  if filetype == "all" then
    return all_snippets
  end

  -- Build list of filetypes to match
  local filetypes_to_match = { filetype }

  if aliases and aliases[filetype] then
    for _, alias_ft in ipairs(aliases[filetype]) do
      table.insert(filetypes_to_match, alias_ft)
    end
  end

  -- Filter snippets
  local result = {}

  for _, snippet in ipairs(all_snippets) do
    for _, ft in ipairs(filetypes_to_match) do
      if vim.tbl_contains(snippet.filetypes, ft) then
        table.insert(result, snippet)
        break
      end
    end
  end

  return result
end

return M
