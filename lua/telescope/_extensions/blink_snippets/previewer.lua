--- Snippet previewer for telescope-blink-snippets
--- @module telescope._extensions.blink_snippets.previewer

local previewers = require("telescope.previewers")

local M = {}

--- Create a buffer previewer for snippets
---@return table Telescope previewer
function M.create()
  return previewers.new_buffer_previewer({
    title = "Snippet Preview",
    define_preview = function(self, entry, _status)
      local snippet = entry.value
      local lines = vim.split(snippet.body, "\n", { plain = true })

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

--- Highlight placeholders in the preview buffer
--- Adds highlights for ${N:text} and $N patterns
---@param bufnr number Buffer number
---@param lines string[] Lines to highlight
function M.highlight_placeholders(bufnr, lines)
  local ns = vim.api.nvim_create_namespace("blink_snippets_preview")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  for i, line in ipairs(lines) do
    local col = 0
    -- Match ${N:text} pattern
    for match_start, match_end in line:gmatch("()%${%d+:[^}]*}()") do
      vim.api.nvim_buf_add_highlight(
        bufnr,
        ns,
        "Special",
        i - 1,
        match_start - 1,
        match_end - 1
      )
    end
    -- Match $N pattern
    for match_start, match_end in line:gmatch("()%$%d+()") do
      vim.api.nvim_buf_add_highlight(
        bufnr,
        ns,
        "Special",
        i - 1,
        match_start - 1,
        match_end - 1
      )
    end
    -- Match $0 (final tabstop)
    for match_start, match_end in line:gmatch("()%$0()") do
      vim.api.nvim_buf_add_highlight(
        bufnr,
        ns,
        "WarningMsg",
        i - 1,
        match_start - 1,
        match_end - 1
      )
    end
  end
end

return M
