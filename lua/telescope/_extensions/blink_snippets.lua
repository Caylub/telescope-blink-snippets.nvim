--- Telescope extension registration for blink_snippets
--- @module telescope._extensions.blink_snippets

local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("telescope-blink-snippets.nvim requires telescope.nvim")
end

local blink_snippets = require("telescope._extensions.blink_snippets.init")

return telescope.register_extension({
  setup = blink_snippets.setup,
  exports = {
    blink_snippets = blink_snippets.blink_snippets,
  },
})
