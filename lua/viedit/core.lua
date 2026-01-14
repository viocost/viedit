M = {}
local Session = require("viedit.session")

local config = require("viedit.config")
local constants = require("viedit.constants")
local ranges = require("viedit.ranges")
local namespace = require("viedit.namespace")

local Marks = require("viedit.marks")
local select = require("viedit.select")
local keymaps = require("viedit.keymaps")

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

			Marks.sync_extmarks(buffer_id, session)

			-- Clear insert_mode_extmark after sync if we're in normal mode
			local mode = vim.api.nvim_get_mode().mode
			if mode == "n" or mode == "v" or mode == "V" then
				session.insert_mode_extmark = nil
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = group_id,
		buffer = buffer_id,
		callback = function()
			Marks.highlight_current_extmark(buffer_id, session)
		end,
	})

	-- Track which extmark we're on when entering insert mode
	vim.api.nvim_create_autocmd({ "InsertEnter" }, {
		group = group_id,
		buffer = buffer_id,
		callback = function()
			session.insert_mode_extmark = session.current_extmark
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

-- Helper to check if next occurrence is adjacent on the right
local function has_adjacent_right(buffer_text, current_end, search_pattern)
	local next_start, _ = buffer_text:find(search_pattern, current_end + 1, true)
	local is_adjacent = next_start ~= nil and next_start == current_end + 1
	return is_adjacent
end

function M.select_all(buffer_number, text, session, lock_to_keyword)
	if not session then
		print("No active session for buffer", buffer_number)
		return {}
	end

	-- Get all lines and treat buffer as single string
	local lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, false)
	local buffer_text = table.concat(lines, "\n")
	local search_pattern = vim.pesc(text)

	-- Search through the entire buffer
	local search_pos = 1
	while true do
		local start_byte, end_byte = buffer_text:find(search_pattern, search_pos, true)
		if not start_byte then
			break
		end

		-- Convert byte position to row/col
		local chars_before_start = start_byte - 1
		local start_row = 0
		local start_col = 0

		for i, line in ipairs(lines) do
			local line_len = #line + 1 -- +1 for newline
			if chars_before_start < line_len then
				start_row = i - 1 -- 0-based
				start_col = chars_before_start
				break
			end
			chars_before_start = chars_before_start - line_len
		end

		local is_valid = true

		-- Check keyword boundaries for normal mode
		if lock_to_keyword then
			local line = lines[start_row + 1]
			if line then
				local range = require("viedit.select").get_keyword_range(line, start_row, start_col + 1)
				if range then
					local keyword = line:sub(range[2] + 1, range[4])
					if keyword ~= text then
						is_valid = false
					end
				else
					is_valid = false
				end
			end
		end

		if is_valid then
			-- Calculate end position
			local text_lines = vim.split(text, "\n", { plain = true })
			local end_row = start_row + #text_lines - 1
			local end_col

			if #text_lines == 1 then
				-- Single line: end_col relative to start
				end_col = start_col + #text
			else
				-- Multi-line: end_col is length of last line
				end_col = #text_lines[#text_lines]
			end

			-- Check if next occurrence is adjacent on the right
			local is_adjacent = has_adjacent_right(buffer_text, end_byte, search_pattern)
			
			-- Set gravity: nil for adjacent extmarks, config values otherwise
			local end_right_gravity, right_gravity
			if is_adjacent then
				end_right_gravity = nil
				right_gravity = nil
			else
				end_right_gravity = config.config.end_right_gravity
				right_gravity = config.config.right_gravity
			end

			-- Create extmark
			local mark = Marks.set(buffer_number, namespace.ns, start_row, start_col, {
				end_row = end_row,
				end_col = end_col,
				hl_group = constants.HL_GROUP_SELECT,
				end_right_gravity = end_right_gravity,
				right_gravity = right_gravity,
			})
			session.marks:add(mark)
		end

		search_pos = end_byte + 1
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

function M.navigate_extmarks(back)
	local buffer_id = vim.api.nvim_get_current_buf()
	if not Session.is_active(buffer_id) then
		print("Viedit session is not active")
		return
	end

	local session = Session.get(buffer_id)

	-- Cycle to the next/previous extmark ID
	local next_id = cycle_extmarks(session, back)
	if not next_id then
		print("No extmarks to navigate")
		return
	end

	-- Get the position of the next extmark
	local mark = Marks.get_details(0, namespace.ns, next_id)
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
	local session = Session.get(buffer_id)

	session:deactivate()

	-- Iterate through all extmarks and remove them
	Marks.clear_all(buffer_id, namespace.ns)
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
	Marks.delete_mark(buffer_id, namespace.ns, mark_id)

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

local function mark_single_selection(buffer_id, session)
	local range = find_word_at_cursor(buffer_id, session.current_selection)
	if range then
		-- Check if there's an adjacent mark on the right
		local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
		local buffer_text = table.concat(lines, "\n")
		local search_pattern = vim.pesc(session.current_selection)
		
		-- Calculate byte position of current match end
		local chars_before = 0
		for i = 1, range.start[1] do
			chars_before = chars_before + #lines[i] + 1
		end
		chars_before = chars_before + range["end"][2]
		
		local is_adjacent = has_adjacent_right(buffer_text, chars_before, search_pattern)
		local end_right_gravity, right_gravity
		if is_adjacent then
			end_right_gravity = nil
			right_gravity = nil
		else
			end_right_gravity = config.config.end_right_gravity
			right_gravity = config.config.right_gravity
		end
		
		local mark = Marks.set(buffer_id, namespace.ns, range.start[1], range.start[2], {
			end_col = range["end"][2],
			hl_group = constants.HL_GROUP_SELECT,
			end_right_gravity = end_right_gravity,
			right_gravity = right_gravity,
		})
		session.marks:add(mark)
		Marks.highlight_current_extmark(buffer_id, session)
	else
		print("Selected text not found under the cursor")
	end
end

local function toggle_single(buffer_id)
	local session = Session.get(buffer_id)
	if session then
		if session.current_extmark then
			remove_extmark(session.current_extmark, buffer_id, session)
		else
			mark_single_selection(buffer_id, session)
		end
	else
		local text = select.get_text_under_cursor(buffer_id)

		if text then
			session = M.start_session(buffer_id)

			session.current_selection = text

			keymaps.set_viedit_keymaps(buffer_id)
			mark_single_selection(buffer_id, session)
		end
		vim.cmd.norm({ "\x1b", bang = true })
	end
end

local function restrict_to_range(range)
	local buffer_id = vim.api.nvim_get_current_buf()
	local session = Session.get(buffer_id)
	if session == nil then
		print("Session not found for buffer", buffer_id)
		return
	end

	local marks = session.marks:get_all()
	local marks_within_range = Marks.from_ids(Marks.filter_marks_within_range(marks, range))

	for _, mark_id in ipairs(marks) do
		if not marks_within_range:contains(mark_id) then
			remove_extmark(mark_id, buffer_id, session)
		end
	end

	if session.marks:size() == 0 then
		close_session(buffer_id)
	end
end

function M.restrict_to_function()
	local range = ranges.get_current_function_range()
	if range then
		restrict_to_range(range)
	end
end

function M.restrict_to_visual_selection()
	local range = ranges.get_visual_selection_range()
	if range then
		restrict_to_range(range)
	end
end

M.close_session = close_session
M.toggle_single = toggle_single

return M
