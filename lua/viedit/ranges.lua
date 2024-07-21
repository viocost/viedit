M = {}

function M.get_current_function_range()
	if not pcall(require, "nvim-treesitter") then
		print("Treesitter is not available")
		return nil
	end

	local buffer_id = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_range = { cursor[1] - 1, cursor[2] }

	local parser = vim.treesitter.get_parser(buffer_id)
	if not parser then
		print("No parser available for the current buffer")
		return nil
	end

	local root = parser:parse()[1]:root()

	local node = root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])

	while node do
		if node:type():match("function") or node:type():match("method") then
			local start_row, start_col, end_row, end_col = node:range()
			return {
				start = { start_row + 1, start_col },
				["end"] = { end_row + 1, end_col },
			}
		end
		node = node:parent()
	end

	return nil
end
return M
