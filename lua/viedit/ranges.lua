M = {}
local ts_utils = require("nvim-treesitter.ts_utils")

function M.get_current_function_range()
	-- Check if Treesitter is available
	if not pcall(require, "nvim-treesitter") then
		print("Treesitter is not available")
		return nil
	end

	local ts_utils = require("nvim-treesitter.ts_utils")

	-- Get the current buffer and cursor position
	local buffer_id = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_range = { cursor[1] - 1, cursor[2] }

	-- Get the root of the syntax tree
	local parser = vim.treesitter.get_parser(buffer_id)
	if not parser then
		print("No parser available for the current buffer")
		return nil
	end

	local root = parser:parse()[1]:root()

	-- Find the smallest node that encompasses the cursor position
	local node = root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])

	-- Debug: Print node types as we traverse up
	print("Traversing nodes:")
	while node do
		print("Node type:", node:type())
		-- Check for various function-like node types
		if node:type():match("function") or node:type():match("method") then
			local start_row, start_col, end_row, end_col = node:range()
			return {
				start = { start_row + 1, start_col },
				["end"] = { end_row + 1, end_col },
			}
		end
		node = node:parent()
	end

	print("No function node found")
	return nil -- No function found
end
return M
