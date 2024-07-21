M = {}

function M.get_keyword_range(line, row, col)
	local range = {}

	local regex = vim.regex([[\k]])
	range = { row, nil, row, nil }

	while not regex:match_str(line:sub(col, col)) do
		col = col + 1
		if #line < col then
			vim.notify("No word under or after cursor", vim.log.levels.WARN)
			return
		end
	end

	while regex:match_str(line:sub(col + 1, col + 1)) do
		col = col + 1
	end
	range[4] = col

	while regex:match_str(line:sub(col, col)) do
		col = col - 1
	end

	range[2] = col

	return range
end

local function get_visual_selection(buffer_id)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1 -- Convert to 0-based index
	local range = {}
	local pos1 = vim.fn.getpos("v")
	local pos2 = vim.fn.getpos(".")
	if pos1[2] > pos2[2] or (pos1[2] == pos2[2] and pos1[3] > pos2[3]) then
		pos1, pos2 = pos2, pos1
	end
	range = { pos1[2] - 1, pos1[3] - 1, pos2[2] - 1, pos2[3] }

	local line = vim.api.nvim_buf_get_lines(buffer_id, row, row + 1, false)[1]
	return line:sub(range[2] + 1, range[4])
end

local function get_keyword_under_cursor(buffer_id)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1 -- Convert to 0-based index
	local col = cursor[2] + 1 -- Adjust for 1-based indexing in VimL

	local line = vim.api.nvim_buf_get_lines(buffer_id, row, row + 1, false)[1]

	local range = M.get_keyword_range(line, row, col)

	if not range then
		return nil
	end

	local keyword = line:sub(range[2] + 1, range[4])
	return keyword
end

function M.get_text_under_cursor(buffer_id)
	local mode = vim.fn.mode()
	if mode == "n" then
		return get_keyword_under_cursor(buffer_id)
	elseif mode == "v" or mode == "V" then
		return get_visual_selection(buffer_id)
	end

	error("Mode is not supported: ", mode)
end
return M
