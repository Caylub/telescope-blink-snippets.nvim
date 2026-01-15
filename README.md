# telescope-blink-snippets.nvim

A Telescope extension for browsing and inserting VSCode-style snippets using Neovim's native `vim.snippet` API.

Perfect for users of [blink.cmp](https://github.com/saghen/blink.cmp) or anyone using native snippets with [friendly-snippets](https://github.com/rafamadriz/friendly-snippets).

## Features

- Browse all available snippets with fuzzy search
- Filter by prefix, name, or description
- Preview snippets with placeholder highlighting
- Insert snippets using native `vim.snippet.expand()`
- Automatic filetype filtering (with option to show all)
- Works with any VSCode-style snippet collection

## Requirements

- Neovim >= 0.10.0 (for `vim.snippet` API)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Optional: [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) or any VSCode-style snippets

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'CayLub/telescope-blink-snippets.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    'rafamadriz/friendly-snippets', -- optional but recommended
  },
  config = function()
    require('telescope').load_extension('blink_snippets')
  end,
  keys = {
    { '<leader>ss', '<cmd>Telescope blink_snippets<cr>', desc = 'Search snippets' },
  },
}
```

## Usage

### Commands

```vim
:Telescope blink_snippets
```

### Lua API

```lua
require('telescope').extensions.blink_snippets.blink_snippets({
  -- Show snippets for all filetypes, not just current buffer
  all_filetypes = false,

  -- Additional snippet directories to search
  search_paths = {},
})
```

### Default Keymaps (in picker)

| Key | Action |
|-----|--------|
| `<CR>` | Insert snippet at cursor |
| `<C-y>` | Yank snippet body |
| `<C-a>` | Toggle all filetypes |

## Configuration

```lua
require('telescope').setup({
  extensions = {
    blink_snippets = {
      -- Snippet search paths (in addition to friendly-snippets)
      search_paths = {
        vim.fn.stdpath('config') .. '/snippets',
      },

      -- Show snippets for all filetypes by default
      all_filetypes = false,

      -- Filetype aliases (e.g., treat 'javascriptreact' as 'javascript')
      filetype_aliases = {
        javascriptreact = { 'javascript' },
        typescriptreact = { 'typescript', 'javascript' },
      },
    },
  },
})
```

## How It Works

1. **Snippet Discovery**: Scans `package.json` files in snippet directories to find VSCode-style snippet collections
2. **Lazy Loading**: Snippets are parsed on first use and cached
3. **Filetype Matching**: Uses the `contributes.snippets` field from `package.json` to match filetypes
4. **Variable Expansion**: Expands VSCode variables before passing to `vim.snippet.expand()`
5. **Native Expansion**: Inserts snippets using `vim.snippet.expand()` for full placeholder support

## VSCode Variable Support

The following VSCode snippet variables are expanded:

| Category | Variables |
|----------|-----------|
| Date/Time | `$CURRENT_YEAR`, `$CURRENT_MONTH`, `$CURRENT_DATE`, `$CURRENT_HOUR`, `$CURRENT_MINUTE`, `$CURRENT_SECOND`, etc. |
| File | `$TM_FILENAME`, `$TM_FILENAME_BASE`, `$TM_FILEPATH`, `$TM_DIRECTORY`, `$RELATIVE_FILEPATH` |
| Editor | `$TM_LINE_NUMBER`, `$TM_LINE_INDEX`, `$TM_CURRENT_LINE`, `$TM_CURRENT_WORD`, `$CURSOR_INDEX`, `$CURSOR_NUMBER` |
| Workspace | `$WORKSPACE_FOLDER`, `$WORKSPACE_NAME` |
| Other | `$CLIPBOARD`, `$UUID`, `$RANDOM`, `$RANDOM_HEX` |
| Comments | `$LINE_COMMENT`, `$BLOCK_COMMENT_START`, `$BLOCK_COMMENT_END` |

### Case Modifiers

Variables support case modifiers with `${VAR:/modifier}` syntax:

- `/upcase` - HELLO WORLD
- `/downcase` - hello world
- `/capitalize` - Hello world
- `/camelcase` - helloWorld
- `/pascalcase` - HelloWorld
- `/snakecase` - hello_world
- `/kebabcase` - hello-world

Example: `${TM_FILENAME_BASE:/pascalcase}`

### TODO

- [ ] Regex-based variable transformations (e.g., `${TM_FILENAME/(.*)\\..+$/$1/}`)

## License

MIT License - see [LICENSE](LICENSE)

## Contributing

Contributions welcome! Please read the contributing guidelines and ensure tests pass before submitting PRs.

```bash
# Run tests
make test

# Or manually
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```
