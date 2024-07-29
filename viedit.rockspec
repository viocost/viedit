package = "viedit"
rockspec_format = "3.0"
version = "1.0.1"
source = {
	url = "https://github.com/viocost/viedit",
}
description = {
	summary = "Viedit: A Neovim plugin for simultaneous editing of multiple occurrences of text",
	detailed = [[
Viedit is a Neovim plugin inspired by Emacs' iedit mode, allowing for quick navigation and simultaneous editing of multiple occurrences of text in a buffer.

## Features

- Highlight current and all matched occurrences
- Simultaneously edit multiple occurrences of text
- Navigation between occurrences
- Toggle individual occurrences
- Restrict occurrences to a current function
- Selection of full keywords only in normal mode and all substrings in visual mode

For more information, visit the [GitHub repository](https://github.com/viocost/viedit).
  ]],
	homepage = "https://github.com/viocost/viedit",
	license = "MIT",
}
build = {
	type = "builtin",
}
