--- VSCode snippet variable expansion
--- @module telescope._extensions.blink_snippets.variables

local M = {}

--- Get current date/time values
---@return table<string, string>
local function get_datetime_vars()
  local now = os.date("*t")
  return {
    CURRENT_YEAR = tostring(now.year),
    CURRENT_YEAR_SHORT = string.sub(tostring(now.year), 3),
    CURRENT_MONTH = string.format("%02d", now.month),
    CURRENT_MONTH_NAME = os.date("%B"),
    CURRENT_MONTH_NAME_SHORT = os.date("%b"),
    CURRENT_DATE = string.format("%02d", now.day),
    CURRENT_DAY_NAME = os.date("%A"),
    CURRENT_DAY_NAME_SHORT = os.date("%a"),
    CURRENT_HOUR = string.format("%02d", now.hour),
    CURRENT_MINUTE = string.format("%02d", now.min),
    CURRENT_SECOND = string.format("%02d", now.sec),
    CURRENT_SECONDS_UNIX = tostring(os.time()),
    CURRENT_TIMEZONE_OFFSET = os.date("%z"),
  }
end

--- Get file-related variables
---@return table<string, string>
local function get_file_vars()
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local filename_base = vim.fn.expand("%:t:r")
  local directory = vim.fn.expand("%:p:h")
  local relative_filepath = vim.fn.expand("%")
  local workspace = vim.fn.getcwd()

  return {
    TM_FILENAME = filename ~= "" and filename or "Untitled",
    TM_FILENAME_BASE = filename_base ~= "" and filename_base or "Untitled",
    TM_FILEPATH = filepath ~= "" and filepath or "",
    TM_DIRECTORY = directory ~= "" and directory or workspace,
    TM_LINE_INDEX = tostring(vim.fn.line(".") - 1),
    TM_LINE_NUMBER = tostring(vim.fn.line(".")),
    TM_CURRENT_LINE = vim.fn.getline("."),
    TM_CURRENT_WORD = vim.fn.expand("<cword>"),
    TM_SELECTED_TEXT = "",
    RELATIVE_FILEPATH = relative_filepath ~= "" and relative_filepath or "",
    WORKSPACE_FOLDER = workspace,
    WORKSPACE_NAME = vim.fn.fnamemodify(workspace, ":t"),
  }
end

--- Get other variables
---@return table<string, string>
local function get_other_vars()
  local clipboard = vim.fn.getreg("+")
  if clipboard == "" then
    clipboard = vim.fn.getreg("*")
  end

  -- Generate UUID
  local random = math.random
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  local uuid = string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)

  return {
    CLIPBOARD = clipboard,
    UUID = uuid,
    RANDOM = string.format("%06d", math.random(0, 999999)),
    RANDOM_HEX = string.format("%06x", math.random(0, 0xffffff)),
  }
end

--- Get comment variables for current filetype
---@return table<string, string>
local function get_comment_vars()
  local line_comment = "//"
  local block_start = "/*"
  local block_end = "*/"

  -- Try to get from commentstring
  local cms = vim.bo.commentstring
  if cms and cms ~= "" then
    if cms:match("%%s") then
      line_comment = cms:gsub("%%s", ""):gsub("%s+$", "")
    end
  end

  -- Common filetype overrides
  local ft = vim.bo.filetype
  local comment_map = {
    lua = { "--", "--[[", "]]" },
    python = { "#", '"""', '"""' },
    ruby = { "#", "=begin", "=end" },
    html = { "<!--", "<!--", "-->" },
    css = { "/*", "/*", "*/" },
    sh = { "#", "", "" },
    bash = { "#", "", "" },
    zsh = { "#", "", "" },
    vim = { '"', "", "" },
  }

  if comment_map[ft] then
    line_comment = comment_map[ft][1]
    block_start = comment_map[ft][2]
    block_end = comment_map[ft][3]
  end

  return {
    LINE_COMMENT = line_comment,
    BLOCK_COMMENT_START = block_start,
    BLOCK_COMMENT_END = block_end,
  }
end

--- Build complete variable table
---@return table<string, string>
function M.get_variables()
  local vars = {}

  for k, v in pairs(get_datetime_vars()) do
    vars[k] = v
  end
  for k, v in pairs(get_file_vars()) do
    vars[k] = v
  end
  for k, v in pairs(get_other_vars()) do
    vars[k] = v
  end
  for k, v in pairs(get_comment_vars()) do
    vars[k] = v
  end

  return vars
end

--- Expand VSCode variables in a snippet body
---@param body string The snippet body
---@return string The body with variables expanded
function M.expand(body)
  local vars = M.get_variables()

  -- Expand ${VAR} and ${VAR:default} syntax (only uppercase letter variables, not tabstops)
  local result = body:gsub("%${([A-Z_][A-Z_0-9]*)}", function(var_name)
    if vars[var_name] then
      return vars[var_name]
    end
    return ""
  end)

  -- Expand ${VAR:default} syntax with defaults
  result = result:gsub("%${([A-Z_][A-Z_0-9]*):([^}]*)}", function(var_name, default)
    if vars[var_name] then
      return vars[var_name]
    end
    return default
  end)

  -- Expand $VAR syntax (without braces, only uppercase)
  result = result:gsub("%$([A-Z_][A-Z_0-9]*)", function(var_name)
    return vars[var_name] or ""
  end)

  return result
end

return M
