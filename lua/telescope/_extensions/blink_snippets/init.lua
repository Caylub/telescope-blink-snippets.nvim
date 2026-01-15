--- telescope-blink-snippets extension entry point
--- @module telescope._extensions.blink_snippets

local config = require("telescope._extensions.blink_snippets.config")
local picker = require("telescope._extensions.blink_snippets.picker")

local M = {}

--- Setup function called by Telescope
---@param ext_config? table Extension configuration from telescope setup
function M.setup(ext_config)
  config.setup(ext_config)
end

--- Main picker function
---@param opts? table Options to override config
function M.blink_snippets(opts)
  opts = opts or {}

  -- Merge with config defaults
  local cfg = config.get()
  opts = vim.tbl_extend("keep", opts, {
    all_filetypes = cfg.all_filetypes,
  })

  picker.pick(opts)
end

return M
