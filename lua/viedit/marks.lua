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

return ExtMarks
