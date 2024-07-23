M = {}
local ns = require("viedit.namespace").ns
local constants = require("viedit.constants")

local function mark_id_to_range(buf, mark_id)
	if mark_id == nil then
		return nil
	end

	local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, mark_id, { details = true })
	if #mark > 0 then
		return { mark[1], mark[2], mark[3].end_row, mark[3].end_col }
	end

	return nil
end

local function update_extmarks(buffer_id, session, new_content)
	new_content = tostring(new_content)
	local marks = session.marks:get_all_reversed()
	for _, mark_id in ipairs(marks) do
		if mark_id == session.current_extmark then
			goto continue
		end
		local range = mark_id_to_range(buffer_id, mark_id)
		if range then
			local start_row, start_col, end_row, end_col = unpack(range)
			-- Delete existing content
			vim.api.nvim_buf_set_text(buffer_id, start_row, start_col, end_row, end_col, {})
			-- Insert new content
			local new_lines = vim.split(new_content, "\n")
			vim.api.nvim_buf_set_text(buffer_id, start_row, start_col, start_row, start_col, new_lines)
			-- Update extmark end position
			local new_end_row = start_row + #new_lines - 1
			local new_end_col = start_col + (#new_lines > 1 and #new_lines[#new_lines] or #new_content)

			local config = require("viedit.config").config

			vim.api.nvim_buf_set_extmark(buffer_id, ns, start_row, start_col, {
				id = mark_id,
				end_row = new_end_row,
				end_col = new_end_col,
				hl_group = constants.HL_GROUP_SELECT,
				right_gravity = config.right_gravity,
				end_right_gravity = config.end_right_gravity,
			})
		end
		::continue::
	end
end

local function sync_extmarks(buffer_id, session)
	local range = mark_id_to_range(buffer_id, session.current_extmark)
	if not range then
		print("No current extmark ")
		return
	end

	local start_row, start_col, end_row, end_col = unpack(range)
	local current_content = vim.api.nvim_buf_get_text(buffer_id, start_row, start_col, end_row, end_col, {})

	if #current_content > 0 and current_content[1] ~= session.current_selection then
		session.current_selection = current_content[1]
		update_extmarks(buffer_id, session, current_content[1])
	end
end

local function is_cursor_on_extmark(buffer_id, extmark_id)
	local extmark = mark_id_to_range(buffer_id, extmark_id)
	if extmark == nil then
		return false
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = cursor[1] - 1
	local col = cursor[2]

	return extmark[1] == line and extmark[2] <= col and col <= extmark[4]
end

local function change_extmark_highlight(buffer, namespace, extmark_id, new_hl_group)
	local config = require("viedit.config").config
	local range = mark_id_to_range(buffer, extmark_id)
	if range == nil then
		print("Extmark %d not found", extmark_id)
		return
	end

	vim.api.nvim_buf_set_extmark(buffer, namespace, range[1], range[2], {
		id = extmark_id,
		hl_group = new_hl_group,
		end_right_gravity = config.end_right_gravity,
		right_gravity = config.right_gravity,
		end_line = range[3],
		end_col = range[4],
		strict = false,
	})
end

local function highlight_current_extrmark(buffer_id, session)
	local current_extmark = nil
	for _, id in ipairs(session.marks:get_all()) do
		if is_cursor_on_extmark(buffer_id, id) then
			change_extmark_highlight(buffer_id, ns, id, constants.HL_GROUP_SELECT_CURRENT)
			current_extmark = id
		else
			change_extmark_highlight(buffer_id, ns, id, constants.HL_GROUP_SELECT)
		end
	end
	session:set_current_extmark(current_extmark)
end

local function filter_marks_within_range(mark_ids, range)
	-- Ensure we have a valid range
	if not range or not range.start or not range["end"] then
		print("Invalid range provided")
		return {}
	end

	local start_line, start_col = range.start[1] - 1, range.start[2]
	local end_line, end_col = range["end"][1] - 1, range["end"][2]

	local filtered_ids = {}
	for _, mark_id in ipairs(mark_ids) do
		-- Get the position of the mark
		local mark_pos = vim.api.nvim_buf_get_extmark_by_id(0, ns, mark_id, {})

		if #mark_pos > 0 then
			local mark_line, mark_col = mark_pos[1], mark_pos[2]

			-- Check if the mark is within the function range
			if
				(mark_line > start_line and mark_line < end_line)
				or (mark_line == start_line and mark_col >= start_col)
				or (mark_line == end_line and mark_col <= end_col)
			then
				table.insert(filtered_ids, mark_id)
			end
		end
	end

	return filtered_ids
end

M.filter_marks_within_range = filter_marks_within_range
M.mark_id_to_range = mark_id_to_range
M.update_extmarks = update_extmarks
M.sync_extmarks = sync_extmarks
M.is_cursor_on_extmark = is_cursor_on_extmark
M.highlight_current_extrmark = highlight_current_extrmark

return M
