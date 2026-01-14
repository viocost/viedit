-- Adjacent extmarks edge case test
-- Testing the boundary between adjacent extmarks
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")
local Marks = require("viedit.marks")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit adjacent extmarks", function()
	before_each(function()
		vim.cmd("enew!")
		local buf = vim.api.nvim_get_current_buf()
		if Session.is_active(buf) then
			viedit.disable()
		end
	end)

	after_each(function()
		local buf = vim.api.nvim_get_current_buf()
		if Session.is_active(buf) then
			viedit.disable()
		end
	end)

	it("should not consider cursor on both adjacent extmarks at boundary", function()
		local buf = vim.api.nvim_get_current_buf()

		-- Create buffer with "xxxxxx"
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"xxxxxx",
		})

		-- Visual select first "xx" (positions 0-1)
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>vl")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		-- Should have 3 extmarks: [0-1], [2-3], [4-5]
		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'xx' occurrences")

		-- Verify extmark positions
		assert.equals(0, extmarks[1][2], "First extmark starts at 0")
		assert.equals(0, extmarks[1][3], "First extmark starts at col 0")
		assert.equals(2, extmarks[1][4].end_col, "First extmark ends at col 2")

		assert.equals(0, extmarks[2][2], "Second extmark starts at row 0")
		assert.equals(2, extmarks[2][3], "Second extmark starts at col 2")
		assert.equals(4, extmarks[2][4].end_col, "Second extmark ends at col 4")

		-- Test cursor at position 2 (boundary between first and second extmark)
		vim.api.nvim_win_set_cursor(0, { 1, 2 })
		vim.wait(10)

		local session = Session.get(buf)
		
		-- Check which extmarks cursor is on
		local on_first = Marks.is_cursor_on(buf, namespace.ns, extmarks[1][1])
		local on_second = Marks.is_cursor_on(buf, namespace.ns, extmarks[2][1])
		local on_third = Marks.is_cursor_on(buf, namespace.ns, extmarks[3][1])

		-- Cursor at position 2 should ONLY be on the second extmark, not the first
		assert.is_false(on_first, "Cursor at position 2 should NOT be on first extmark [0-1]")
		assert.is_true(on_second, "Cursor at position 2 SHOULD be on second extmark [2-3]")
		assert.is_false(on_third, "Cursor at position 2 should NOT be on third extmark [4-5]")
	end)

	it("should insert correctly at boundary between adjacent extmarks", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"xxxxxx",
		})

		-- Visual select first "xx"
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>vl")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'xx' occurrences")

		-- Position cursor at position 1 and append (insert between 1 and 2)
		vim.api.nvim_win_set_cursor(0, { 1, 1 })
		
		-- Update current_extmark to reflect cursor position
		local session = Session.get(buf)
		Marks.highlight_current_extmark(buf, session)
		vim.wait(10)
		
		-- Manually set insert_mode_extmark since autocmds don't fire in tests
		session.insert_mode_extmark = session.current_extmark
		
		print("Before append - current_extmark:", session.current_extmark)
		print("Before append - insert_mode_extmark:", session.insert_mode_extmark)
		print("Before append - buffer:", vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1])
		
		-- Check all extmarks before edit
		local extmarks_before = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		for i, mark in ipairs(extmarks_before) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			print(string.format("Extmark %d before: [%d,%d]->[%d,%d] = '%s'", i, mark[2], mark[3], mark[4].end_row, mark[4].end_col, table.concat(content, "\\n")))
		end
		
		feedkeys("aa<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)
		
		-- Manually clear insert_mode_extmark after sync
		session.insert_mode_extmark = nil
		
		print("After append - current_extmark:", session.current_extmark)
		print("After append - insert_mode_extmark:", session.insert_mode_extmark)
		print("After append - buffer:", vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1])
		
		-- Check all extmarks after edit
		local extmarks_after = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		for i, mark in ipairs(extmarks_after) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			print(string.format("Extmark %d after: [%d,%d]->[%d,%d] = '%s'", i, mark[2], mark[3], mark[4].end_row, mark[4].end_col, table.concat(content, "\\n")))
		end

		-- Should get "xxaxxaxxaxx" (each "xx" becomes "xxa")
		-- NOT "axxxxaxx" (which would happen if insert affected multiple extmarks)
		local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
		assert.equals("xxaxxaxxa", line, "Should insert 'a' in each extmark separately")

		-- Verify extmark contents
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("xxa", content_str, string.format("Extmark %d should be 'xxa'", i))
		end
	end)

	it("should handle insertion at exact boundary position", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"xxxxxx",
		})

		-- Visual select first "xx"
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>vl")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		-- Position cursor at position 2 (between first and second extmark)
		vim.api.nvim_win_set_cursor(0, { 1, 2 })
		
		-- Update current_extmark to reflect cursor position
		local session = Session.get(buf)
		Marks.highlight_current_extmark(buf, session)
		vim.wait(10)

		-- Insert at this position
		feedkeys("iZ<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Should get "xxZxxZxx" (Z prepended to each occurrence)
		local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
		assert.equals("ZxxZxxZxx", line, "Should prepend 'Z' to each extmark")

		-- Verify all extmarks have Z prepended
		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("Zxx", content_str, string.format("Extmark %d should be 'Zxx'", i))
		end
	end)
end)
