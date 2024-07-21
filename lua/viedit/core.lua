M = {}
local Session = require("viedit.session")

local config = require("viedit/config")
local constants = require("viedit/constants")
local ranges = require("viedit/ranges")
local namespace = require("viedit.namespace")
local cb = require("viedit/callback")

local Marks = require("viedit/marks")
local util = require("viedit/util")

function M.start_session(buffer_id)
	local group_id = vim.api.nvim_create_augroup("Viedit", { clear = false })
	local session = Session.new(buffer_id, group_id)

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
		group = group_id,
		buffer = buffer_id,
		callback = function()
			if vim.fn.undotree(buffer_id).seq_cur ~= vim.fn.undotree(buffer_id).seq_last then
				return
			end

			vim.cmd("silent! undojoin")

			util.sync_extmarks(buffer_id, session)
		end,
	})
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = group_id,
		buffer = buffer_id,
		callback = function()
			cb.on_cursor_move(buffer_id, session)
		end,
	})
	return session
end

local function close_session(buffer_id)
	local session = Session.get(buffer_id)
	session:deactivate()

	vim.api.nvim_del_augroup_by_id(session.augroup_id)
	Session.delete(buffer_id)
end

function M.select_all(buffer_number, text, session, lock_to_keyword)
	if not session then
		print("No active session for buffer", buffer_number)
		return {}
	end

	local lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)

	for line_num, line in ipairs(lines) do
		local start_idx = 1
		while true do
			local start_pos, end_pos = line:find(text, start_idx, true)
			if not start_pos then
				break
			end

			local is_valid = true
			if lock_to_keyword then
				local range = require("viedit/select").get_keyword_range(line, line_num, start_pos)

				local keyword = line:sub(range[2] + 1, range[4])
				if keyword ~= text then
					is_valid = false
				end
			end

			if is_valid then
				local mark = vim.api.nvim_buf_set_extmark(buffer_number, namespace.ns, line_num - 1, start_pos - 1, {
					end_col = end_pos,
					hl_group = constants.HL_GROUP_SELECT,
					end_right_gravity = config.end_right_gravity,
					right_gravity = config.righ_gravity,
				})
				session.marks:add(mark)
			end

			start_idx = end_pos + 1
		end
	end
end

local function cycle_extmarks(session, back)
	local extmarks = session.marks:get_all()
	local current_id = session.current_extmark

	-- Ensure we have extmarks to cycle through
	if #extmarks == 0 then
		return nil
	end

	-- Find the index of the current extmark
	local current_index = nil
	for i, id in ipairs(extmarks) do
		if id == current_id then
			current_index = i
			break
		end
	end

	if not current_index then
		return extmarks[1]
	end

	-- Determine the next index based on direction
	local next_index
	if back then
		next_index = (current_index - 2 + #extmarks) % #extmarks + 1
	else
		next_index = current_index % #extmarks + 1
	end

	return extmarks[next_index]
end

local function compare_extmarks_by_position(id1, id2)
	local buffer_id = vim.api.nvim_get_current_buf()

	-- Get positions of both extmarks
	local pos1 = vim.api.nvim_buf_get_extmark_by_id(buffer_id, namespace.ns, id1, {})
	local pos2 = vim.api.nvim_buf_get_extmark_by_id(buffer_id, namespace.ns, id2, {})

	-- Check if both positions are valid
	if #pos1 == 0 or #pos2 == 0 then
		error("Invalid extmark ID encountered")
	end

	-- Compare row positions first
	if pos1[1] ~= pos2[1] then
		return pos1[1] < pos2[1]
	end

	-- If rows are the same, compare column positions
	return pos1[2] < pos2[2]
end

-- Usage example:
local function sort_extmarks(extmark_ids)
	table.sort(extmark_ids, compare_extmarks_by_position)
	return extmark_ids
end

function M.navigate_extmarks(back)
	local buffer_id = vim.api.nvim_get_current_buf()
	local session = Session.get(buffer_id)
	local extmarks = session.marks:get_all()

	-- Cycle to the next/previous extmark ID
	local next_id = cycle_extmarks(session, back)
	if not next_id then
		print("No extmarks to navigate")
		return
	end

	-- Get the position of the next extmark
	local mark = vim.api.nvim_buf_get_extmark_by_id(0, namespace.ns, next_id, { details = true })
	if #mark == 0 then
		print("Failed to get extmark position")
		return
	end

	local row, col, details = unpack(mark)

	-- Move the cursor to the start of the extmark
	vim.api.nvim_win_set_cursor(0, { row + 1, col }) -- +1 because nvim_win_set_cursor is 1-indexed for rows

	-- Update the current extmark in the session
	session.current_extmark = next_id

	-- Optionally, scroll the window to ensure the cursor is visible
	vim.api.nvim_command("normal! zz")
end

-- Deselect all occurrences in the current buffer
function M.deselect_all(buffer_id)
	local extmarks = vim.api.nvim_buf_get_extmarks(buffer_id, namespace.ns, 0, -1, {})
	local session = Session.get(buffer_id)

	session:deactivate()

	-- Iterate through all extmarks and remove them
	vim.api.nvim_buf_clear_namespace(buffer_id, namespace.ns, 0, -1)
	session.marks:clear()
end

-- Check if a session is active for the given buffer
function M.is_session_active(buffer_id)
	return Session.is_active(buffer_id)
	-- Implementation details
end

local function remove_extmark(mark_id, buffer_id, session)
	if session.current_extmark == mark_id then
		session.current_extmark = nil
	end

	session.marks:delete(mark_id)
	vim.api.nvim_buf_del_extmark(buffer_id, namespace.ns, mark_id)

	if session.marks:size() == 0 then
		close_session(buffer_id)
	end
end

local function find_word_at_cursor(buffer_id, selected_text)
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_row, cursor_col = cursor_pos[1] - 1, cursor_pos[2]
	local line = vim.api.nvim_buf_get_lines(buffer_id, cursor_row, cursor_row + 1, false)[1]

	local search_start = 0
	while true do
		local match_start, match_end = line:find(selected_text, search_start, true)

		if not match_start then
			return nil
		end

		if cursor_col >= match_start - 1 and cursor_col < match_end then
			return {
				start = { cursor_row, match_start - 1 },
				["end"] = { cursor_row, match_end },
			}
		end

		search_start = match_start + 1

		if search_start > cursor_col then
			return nil
		end
	end
end

local function toggle_single(buffer_id)
	local session = Session.get(buffer_id)
	if session.current_extmark then
		remove_extmark(session.current_extmark, buffer_id, session)
	else
		local range = find_word_at_cursor(buffer_id, session.current_selection)
		if range then
			local mark = vim.api.nvim_buf_set_extmark(buffer_id, namespace.ns, range.start[1], range.start[2], {
				end_col = range["end"][2],
				hl_group = constants.HL_GROUP_SELECT,
				end_right_gravity = config.end_right_gravity,
				right_gravity = config.righ_gravity,
			})
			session.marks:add(mark)
			util.highlight_current_extrmark(buffer_id, session)
		else
			print("Selected text not found under the cursor")
		end
	end
end

function M.restrict_to_function()
	local range = ranges.get_current_function_range()

	local buffer_id = vim.api.nvim_get_current_buf()
	local session = Session.get(buffer_id)
	if session == nil then
		print("Session not found for buffer", buffer_id)
		return
	end
	local marks = session.marks:get_all()

	local marks_within_range = Marks.from_ids(util.filter_marks_within_range(marks, range))

	for _, mark_id in ipairs(marks) do
		if not marks_within_range:contains(mark_id) then
			remove_extmark(mark_id, buffer_id, session)
		end
	end

	if session.marks:size() == 0 then
		close_session(buffer_id)
	end
end

M.close_session = close_session
M.toggle_single = toggle_single

return M
