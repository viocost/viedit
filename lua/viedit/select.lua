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
	local pos1 = vim.fn.getpos("v")
	local pos2 = vim.fn.getpos(".")
	
	-- Ensure pos1 is the start
	if pos1[2] > pos2[2] or (pos1[2] == pos2[2] and pos1[3] > pos2[3]) then
		pos1, pos2 = pos2, pos1
	end
	
	local start_row = pos1[2] - 1  -- Convert to 0-based
	local start_col = pos1[3] - 1  -- Convert to 0-based
	local end_row = pos2[2] - 1    -- Convert to 0-based
	local end_col = pos2[3]        -- Keep 1-based for this position
	
	-- Get all lines in the selection
	local lines = vim.api.nvim_buf_get_lines(buffer_id, start_row, end_row + 1, false)
	
	if #lines == 0 then
		return nil
	end
	
	-- Single line selection
	if #lines == 1 then
		return lines[1]:sub(start_col + 1, end_col)
	end
	
	-- Multi-line selection
	lines[1] = lines[1]:sub(start_col + 1)
	lines[#lines] = lines[#lines]:sub(1, end_col)
	
	return table.concat(lines, "\n")
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
