# Viedit

Viedit is a Neovim plugin inspired by Emacs' iedit mode, allowing for quick naviagtion and simultaneous editing of multiple occurrences of text in a buffer.

https://github.com/user-attachments/assets/6dd95c99-f048-4b31-a4b6-a239993fed0a

## Features

- Highlight current and all matched occurrences
- Simultaneously edit multiple occurrences of text
- Navigation between occurrences
- Toggle individual occurrences
- Restrict occurrences to a current function
- Selection of full keywords only in normal mode and all substrings in visual mode

## Installation

### Install the plugin

Use your preferred Neovim plugin manager to install Viedit. Here are examples for popular plugin managers:

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'viocost/viedit'
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'viocost/viedit'
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'viocost/viedit',
  config = function()
    require('viedit').setup()
  end
}
```

### Setup key bindings

For example in lazyvim:

```lua
map({ "n" }, ";", '<cmd>lua require("viedit").toggle_all()<CR>', {
  desc = "viedit mode",
})

map({ "v" }, ";", '<cmd>lua require("viedit").toggle_all()<CR>', {
  desc = "viedit mode",
})

map({ "n" }, "<leader>rr", '<cmd>lua require("viedit").reload()<CR>', {
  desc = "vedit mode reload",
})

map({ "n" }, "<leader>rf", '<cmd>lua require("viedit").restrict_to_function()<CR>', {
  desc = "restrict to function",
})
```

## Configuration

Viedit comes with following defaults, but you can customize its behavior. Here's an example configuration with all available options:

```lua
require('viedit').setup({
	-- Highlight group for marked text
	-- Can use any highlight group definitions
	highlight = {

		fg = "#000000",
		bg = "#fff98c",
	},

	-- Highlight group for the marked text where cursor currently is
	current_highlight = {
		link = "CurSearch",
	},

	-- Determines the behavior of the end of the mark when text is inserted
	-- true: the end of the mark stays at its position (moves with inserted text)
	-- false: the end of the mark moves as text is inserted
	end_right_gravity = true,

	-- Determines the behavior of the start of the mark when text is inserted
	-- true: the start of the mark stays at its position (moves with inserted text)
	-- false: the start of the mark remains fixed as text is inserted
	right_gravity = false,

	-- It may be useful to keep semantics of next/previous keys
	-- If this is true, default mappings for specified keys will be overriden
	-- to do viedit operations while viedit mode is enabled
	-- true: override specified keys while in viedit mode
	-- false: do not override any keys
	override_keys = true,

	-- Defines keys that will be overriden and mapped to viedit operations
	-- If override_keys is off - this won't be applied
	keys = {
		-- Key to move to the next occurrence of the marked text
		next_occurrence = "n",
		-- Key to move to the previous occurrence of the marked text
		previous_occurrence = "N",
		-- Toggle individual occurrence to/from selection
		toggle_single = "t",
	},
})
```

## Usage

Viedit provides several functions to manipulate text selections and navigate through them:

### Toggle All Occurrences

```lua
require('viedit').toggle_all()
```

This function toggles the selection of all occurrences of the word under the cursor in the buffer.

- In **normal mode**, it selects only independent keyword occurrences. Substrings within larger words are not selected.
- In **visual mode**, it selects all substrings, regardless of keyword boundaries.
- If any occurrences are already selected, calling this function will deselect everything and end the session.

### Toggle Single Occurrence

```lua
require('viedit').toggle_single()
```

This function toggles the selection of a single occurrence:

- If the cursor is inside a selected occurrence, it will deselect it.
- If the cursor is on non-selected text that matches the selected text, it will select it.
- If no text selected, the function will start a new viedit session with the keyword or a visual selection under the cursor
- If the text under the cursor does not match the selected text, it will do nothing.

### Navigate Through Occurrences

```lua
-- Move to next occurrence
require('viedit').step()

-- Move to previous occurrence
require('viedit').step({back = true})
```

This function allows you to jump to the next or previous selected occurrence. Pass `{back = true}` to traverse backward.

### Restrict to Function

```lua
require('viedit').restrict_to_function()
```

This function restricts the selection to occurrences within the current function scope.

### Setup

```lua
require('viedit').setup(options)
```

Use this function to configure Viedit with custom options. See the Configuration section for available options.

### Reload Plugin (Development)

```lua
require('viedit').reload()
```

This function is for development purposes. It hot-reloads the plugin by clearing the plugin's modules from `package.loaded` and reloading the Neovim configuration.

## Keybindings

### Option 1: Dynamic reassign

Viedit allows you to override existing keybindings while in viedit mode.
This may be useful to keep existing semantics of navigating selected occurrences.

For example, if you used to jump between selections with "n" for next and "N" for previous,
and wish to use the same keys for viedit, set following config:

```lua
require('viedit').setup({
  ...
  override_keys = true,
  keys = {
    next_occurrence = "n",
    previous_occurrence = "N",
  },
  ...
})
```

This will dynamically reassign those keys to handle viedit commands, once you select something, and restore original bindings once you deselect.

How it works:

1. Before selection: Keys retain their original Neovim bindings.
2. After selecting text with Viedit: Specified keys (e.g., `n` and `N`) are reassigned to Viedit operations.
   - `n` will move to the next occurrence of the selected text.
   - `N` will move to the previous occurrence of the selected text.
3. After deselecting: Keys are immediately restored to their original Neovim bindings.

### Option 2: Disable Key Override

If you prefer complete control over your keybindings, you can disable the key override feature:

```lua
require('viedit').setup({
  override_keys = false,
})
```

With this setting, Viedit will not alter any key behaviors. Instead, you have the flexibility to assign Viedit operations to any keys you prefer using Neovim's keymapping system and Viedit's public API.

Example of custom keybindings:

```lua
vim.keymap.set('n', '<leader>vn', require('viedit').step, { desc = 'Viedit: Next occurrence' })
vim.keymap.set('n', '<leader>vp', function() require('viedit').step({back = true}) end, { desc = 'Viedit: Previous occurrence' })
```

## Acknowledgements

Viedit is heavily inspired by

1. [iedit](https://github.com/victorhge/iedit) mode in Emacs.

2. [iedit.nvim](https://github.com/altermo/iedit.nvim), another Neovim implementation of the iedit concept.
   Their work provided valuable insights and motivation for creating Viedit.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.
