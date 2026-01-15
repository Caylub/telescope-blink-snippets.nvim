--- Telescope picker for snippets
--- @module telescope._extensions.blink_snippets.picker

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local loader = require("telescope._extensions.blink_snippets.loader")
local config = require("telescope._extensions.blink_snippets.config")
local variables = require("telescope._extensions.blink_snippets.variables")

local M = {}

--- Create an entry for a snippet
---@param snippet Snippet
---@return table Telescope entry
function M.make_entry(snippet)
  local prefix_str = table.concat(snippet.prefix, ", ")
  local desc = snippet.description or ""

  -- Display format: prefix | name | description
  local display = string.format("%-15s | %-25s | %s", prefix_str, snippet.name, desc)

  -- Ordinal for fuzzy matching includes all searchable fields
  local ordinal = prefix_str .. " " .. snippet.name .. " " .. desc

  return {
    value = snippet,
    display = display,
    ordinal = ordinal,
  }
end

--- Format snippet body for preview display
---@param body string The snippet body
---@return string[] Lines for preview
function M.format_body_for_preview(body)
  return vim.split(body, "\n", { plain = true })
end

--- Get snippets based on options
---@param opts table Options (all_filetypes, etc.)
---@return Snippet[]
function M.get_snippets(opts)
  local cfg = config.get()
  local search_paths = config.get_search_paths()
  local aliases = cfg.filetype_aliases

  if opts.all_filetypes then
    return loader.get_snippets_for_filetype("all", search_paths, aliases)
  end

  local filetype = vim.bo.filetype
  if filetype == "" then
    filetype = "all"
  end

  return loader.get_snippets_for_filetype(filetype, search_paths, aliases)
end

--- Insert a snippet at the current cursor position
---@param snippet Snippet
function M.insert_snippet(snippet)
  -- Expand VSCode variables before passing to vim.snippet
  local body = variables.expand(snippet.body)
  vim.snippet.expand(body)
end

--- Create the snippet previewer
---@return table Telescope previewer
local function create_previewer()
  return previewers.new_buffer_previewer({
    title = "Snippet Preview",
    define_preview = function(self, entry, _status)
      local snippet = entry.value
      local lines = M.format_body_for_preview(snippet.body)

      -- Add header info
      local header = {
        "Name: " .. snippet.name,
        "Prefix: " .. table.concat(snippet.prefix, ", "),
        "Filetypes: " .. table.concat(snippet.filetypes, ", "),
        "",
        "--- Body ---",
        "",
      }

      -- Combine header and body
      local preview_lines = vim.list_extend(header, lines)

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines)

      -- Try to set filetype for syntax highlighting
      local ft = snippet.filetypes[1]
      if ft then
        vim.bo[self.state.bufnr].filetype = ft
      end
    end,
  })
end

--- Open the snippet picker
---@param opts? table Options to override config
function M.pick(opts)
  opts = opts or {}

  local snippets = M.get_snippets(opts)

  if #snippets == 0 then
    vim.notify("No snippets found for current filetype", vim.log.levels.INFO)
    return
  end

  pickers
    .new(opts, {
      prompt_title = "Snippets",
      finder = finders.new_table({
        results = snippets,
        entry_maker = M.make_entry,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = create_previewer(),
      attach_mappings = function(prompt_bufnr, map)
        -- Default action: insert snippet
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            M.insert_snippet(selection.value)
          end
        end)

        -- <C-y> to yank snippet body
        map("i", "<C-y>", function()
          local selection = action_state.get_selected_entry()
          if selection then
            vim.fn.setreg("+", selection.value.body)
            vim.notify("Snippet body yanked to clipboard", vim.log.levels.INFO)
          end
        end)

        -- <C-a> to toggle all filetypes
        map("i", "<C-a>", function()
          actions.close(prompt_bufnr)
          opts.all_filetypes = not opts.all_filetypes
          M.pick(opts)
        end)

        return true
      end,
    })
    :find()
end

return M
