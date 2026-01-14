-- Centralized Extmark API
-- All native vim.api extmark calls are encapsulated here
-- This module provides a clean interface for extmark manipulation

local ExtMarks = {}
ExtMarks.__index = ExtMarks

-- ============================================================================
-- PRIVATE API - Native vim.api calls (internal use only)
-- ============================================================================

-- Set an extmark with optional parameters
local function _set_extmark(buf, ns, row, col, opts)
	return vim.api.nvim_buf_set_extmark(buf, ns, row, col, opts or {})
end

-- Get extmark position by ID
local function _get_extmark_by_id(buf, ns, id, opts)
	return vim.api.nvim_buf_get_extmark_by_id(buf, ns, id, opts or {})
end

-- Get all extmarks in a range
local function _get_extmarks(buf, ns, start, end_, opts)
	return vim.api.nvim_buf_get_extmarks(buf, ns, start, end_, opts or {})
end

-- Delete an extmark by ID
local function _del_extmark(buf, ns, id)
	return vim.api.nvim_buf_del_extmark(buf, ns, id)
end

-- Clear all extmarks in namespace
local function _clear_namespace(buf, ns, line_start, line_end)
	return vim.api.nvim_buf_clear_namespace(buf, ns, line_start, line_end)
end

-- ============================================================================
-- PUBLIC API - High-level extmark operations
-- ============================================================================

-- Create a new extmark with standard options
function ExtMarks.set(buf, ns, row, col, opts)
	opts = opts or {}
	return _set_extmark(buf, ns, row, col, opts)
end

-- Update an existing extmark (set with id parameter)
function ExtMarks.update(buf, ns, row, col, id, opts)
	opts = opts or {}
	opts.id = id
	return _set_extmark(buf, ns, row, col, opts)
end

-- Get extmark position by ID (returns {row, col} or empty table)
function ExtMarks.get_position(buf, ns, id)
	return _get_extmark_by_id(buf, ns, id, {})
end

-- Get extmark with full details (returns {row, col, details})
function ExtMarks.get_details(buf, ns, id)
	return _get_extmark_by_id(buf, ns, id, { details = true })
end

-- Convert extmark ID to range {start_row, start_col, end_row, end_col}
function ExtMarks.get_range(buf, ns, id)
	local mark = _get_extmark_by_id(buf, ns, id, { details = true })
	if #mark > 0 then
		return { mark[1], mark[2], mark[3].end_row, mark[3].end_col }
	end
	return nil
end

-- Get all extmarks in buffer (returns array of {id, row, col})
function ExtMarks.get_all(buf, ns)
	return _get_extmarks(buf, ns, 0, -1, {})
end

-- Get all extmarks with details
function ExtMarks.get_all_with_details(buf, ns)
	return _get_extmarks(buf, ns, 0, -1, { details = true })
end

-- Delete an extmark by ID from the buffer
function ExtMarks.delete_mark(buf, ns, id)
	return _del_extmark(buf, ns, id)
end

-- Clear all extmarks in the namespace
function ExtMarks.clear_all(buf, ns)
	return _clear_namespace(buf, ns, 0, -1)
end

-- Check if cursor is on extmark
function ExtMarks.is_cursor_on(buf, ns, id)
	local range = ExtMarks.get_range(buf, ns, id)
	if not range then
		return false
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_row = cursor[1] - 1
	local cursor_col = cursor[2]

	local start_row, start_col, end_row, end_col = unpack(range)

	-- Check if cursor row is within the extmark range
	if cursor_row < start_row or cursor_row > end_row then
		return false
	end

	-- If cursor is on start row, check if after start_col
	if cursor_row == start_row and cursor_col < start_col then
		return false
	end

	-- If cursor is on end row, check if before end_col (end_col is exclusive)
	if cursor_row == end_row and cursor_col >= end_col then
		return false
	end

	return true
end

-- Compare two extmarks by position (for sorting)
function ExtMarks.compare_positions(buf, ns, id1, id2)
	local pos1 = _get_extmark_by_id(buf, ns, id1, {})
	local pos2 = _get_extmark_by_id(buf, ns, id2, {})

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

-- ============================================================================
-- ExtMarks Set - Collection management
-- ============================================================================

function ExtMarks.new()
	local self = setmetatable({}, ExtMarks)
	self.set = {}
	return self
end

function ExtMarks.from_ids(ids)
	local self = ExtMarks.new()
	for _, id in ipairs(ids) do
		self.set[id] = true
	end
	return self
end

function ExtMarks:add(extmark)
	self.set[extmark] = true
end

function ExtMarks:delete(extmark)
	self.set[extmark] = nil
end

function ExtMarks:contains(extmark)
	return self.set[extmark] ~= nil
end

function ExtMarks:get_all()
	local extmarks = {}
	for key, _ in pairs(self.set) do
		table.insert(extmarks, key)
	end
	return extmarks
end

function ExtMarks:get_all_reversed()
	local extmarks = {}
	for key, _ in pairs(self.set) do
		table.insert(extmarks, key)
	end
	table.sort(extmarks, function(a, b)
		return a > b
	end) -- Sort in descending order
	return extmarks
end

function ExtMarks:size()
	return #vim.tbl_keys(self.set)
end

function ExtMarks:clear()
	self.set = {}
end

-- ============================================================================
-- HIGH-LEVEL OPERATIONS - Internal helper functions
-- ============================================================================

local ns = require("viedit.namespace").ns
local constants = require("viedit.constants")

-- Convert mark ID to range
local function mark_id_to_range(buf, mark_id)
	if mark_id == nil then
		return nil
	end
	return ExtMarks.get_range(buf, ns, mark_id)
end

-- Update all extmarks with new content
local function update_extmarks(buffer_id, session, new_content_lines)
	-- new_content_lines is an array of lines

	-- Use insert_mode_extmark if we're in insert mode, otherwise use current_extmark
	local extmark_to_skip = session.insert_mode_extmark or session.current_extmark

	local marks = session.marks:get_all_reversed()
	for _, mark_id in ipairs(marks) do
		if mark_id == extmark_to_skip then
			goto continue
		end
		local range = mark_id_to_range(buffer_id, mark_id)
		if range then
			local start_row, start_col, end_row, end_col = unpack(range)

			-- Delete existing content at this extmark
			vim.api.nvim_buf_set_text(buffer_id, start_row, start_col, end_row, end_col, {})

			-- Insert new content line by line
			vim.api.nvim_buf_set_text(buffer_id, start_row, start_col, start_row, start_col, new_content_lines)

			-- Calculate new end position based on number of lines
			local num_lines = #new_content_lines
			local new_end_row = start_row + num_lines - 1
			local new_end_col

			if num_lines == 1 then
				-- Single line: end_col is start_col + length of line
				new_end_col = start_col + #new_content_lines[1]
			else
				-- Multi-line: end_col is the length of the last line
				new_end_col = #new_content_lines[num_lines]
			end

			local config = require("viedit.config").config

			-- Get original gravity from extmark details to preserve it
			local extmark_details = ExtMarks.get_details(buffer_id, ns, mark_id)
			local end_right_gravity = config.end_right_gravity
			local right_gravity = config.right_gravity
			
			if extmark_details and extmark_details[3] then
				end_right_gravity = extmark_details[3].end_right_gravity
				right_gravity = extmark_details[3].right_gravity
			end

			-- Update extmark with new dimensions, preserving original gravity
			ExtMarks.update(buffer_id, ns, start_row, start_col, mark_id, {
				end_row = new_end_row,
				end_col = new_end_col,
				hl_group = constants.HL_GROUP_SELECT,
				right_gravity = right_gravity,
				end_right_gravity = end_right_gravity,
			})
		end
		::continue::
	end
end

-- Check if cursor is on extmark
local function is_cursor_on_extmark(buffer_id, extmark_id)
	return ExtMarks.is_cursor_on(buffer_id, ns, extmark_id)
end

-- Change extmark highlight
local function change_extmark_highlight(buffer, namespace, extmark_id, new_hl_group)
	local config = require("viedit.config").config
	local range = mark_id_to_range(buffer, extmark_id)
	if range == nil then
		print("Extmark %d not found", extmark_id)
		return
	end

	local end_right_gravity = config.end_right_gravity
	local right_gravity = config.right_gravity

	local extmark = ExtMarks.get_details(buffer, namespace, extmark_id)
	local details = extmark[3]

	if details ~= nil then
		end_right_gravity = details.end_right_gravity
		right_gravity = details.right_gravity
	end

	ExtMarks.update(buffer, namespace, range[1], range[2], extmark_id, {
		hl_group = new_hl_group,
		end_line = range[3],
		end_col = range[4],
		strict = false,
		right_gravity = right_gravity,
		end_right_gravity = end_right_gravity,
	})
end

-- Highlight current extmark based on cursor position
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

-- ============================================================================
-- PUBLIC HIGH-LEVEL OPERATIONS
-- ============================================================================

-- Sync extmarks: Update all extmarks based on changes to one extmark
function ExtMarks.sync_extmarks(buffer_id, session)
	-- Use insert_mode_extmark if we're in insert mode, otherwise use current_extmark
	local extmark_to_sync = session.insert_mode_extmark or session.current_extmark

	local range = mark_id_to_range(buffer_id, extmark_to_sync)
	
	-- If no extmark is currently active (e.g., after deletion), find the changed extmark
	if not range then
		-- Check all marks to find one that has changed content
		for _, mark_id in ipairs(session.marks:get_all()) do
			local mark_range = mark_id_to_range(buffer_id, mark_id)
			if mark_range then
				local m_start_row, m_start_col, m_end_row, m_end_col = unpack(mark_range)
				local mark_content_lines = vim.api.nvim_buf_get_text(buffer_id, m_start_row, m_start_col, m_end_row, m_end_col, {})
				local mark_content_str = table.concat(mark_content_lines, "\n")
				
				-- If this mark's content differs from stored selection, use it as sync source
				if mark_content_str ~= session.current_selection then
					extmark_to_sync = mark_id
					range = mark_range
					break
				end
			end
		end
		
		-- If still no range found, nothing to sync
		if not range then
			return
		end
	end

	local start_row, start_col, end_row, end_col = unpack(range)

	-- Get current content as array of lines
	local current_content_lines = vim.api.nvim_buf_get_text(buffer_id, start_row, start_col, end_row, end_col, {})

	-- Join lines to compare with stored selection
	local current_content_str = table.concat(current_content_lines, "\n")

	-- If content changed, sync all other extmarks
	if current_content_str ~= session.current_selection then
		session.current_selection = current_content_str
		update_extmarks(buffer_id, session, current_content_lines)
	end
end

-- Highlight current extmark: Update highlighting based on cursor position
function ExtMarks.highlight_current_extmark(buffer_id, session)
	return highlight_current_extrmark(buffer_id, session)
end

-- Filter marks within range: Get only marks that fall within a given range
function ExtMarks.filter_marks_within_range(mark_ids, range)
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
		local mark_pos = ExtMarks.get_position(0, ns, mark_id)

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

return ExtMarks
