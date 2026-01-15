--- Minimal init for running tests
--- Usage: nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/"

-- Add plugin paths
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.runtimepath:prepend(plugin_path)

-- Add dependencies from standard locations
local function add_plugin(name)
  local paths = {
    vim.fn.stdpath('data') .. '/lazy/' .. name,
    vim.fn.stdpath('data') .. '/site/pack/vendor/start/' .. name,
    vim.fn.expand('~/.local/share/nvim/site/pack/vendor/start/' .. name),
  }
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 1 then
      vim.opt.runtimepath:prepend(path)
      return true
    end
  end
  return false
end

-- Required dependencies
assert(add_plugin('plenary.nvim'), 'plenary.nvim not found')
assert(add_plugin('telescope.nvim'), 'telescope.nvim not found')

-- Optional dependencies
add_plugin('friendly-snippets')

-- Basic settings for tests
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false

-- Load plenary test harness
require('plenary.busted')
