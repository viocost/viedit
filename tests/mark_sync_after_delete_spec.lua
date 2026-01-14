-- Mark synchronization test after word deletion
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit mark sync after deletion", function()
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

	it("should sync single character deletion (x) across all marks", function()
		local buf = vim.api.nvim_get_current_buf()

		-- Create buffer with four lines of single "h"
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"h",
			"h",
			"h",
			"h",
		})

		-- Place cursor on first "h" and select all in normal mode
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		-- Verify we have 4 extmarks
		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(4, #extmarks, "Should have 4 'h' occurrences")

		-- Verify initial content
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("h", content_str, string.format("Extmark %d should initially have 'h'", i))
		end

		-- Place cursor on first "h" and delete with x
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("x")
		vim.wait(10)

		-- Simulate real-world scenario: CursorMoved fires before TextChanged
		-- This clears current_extmark, preventing sync
		vim.cmd("doautocmd CursorMoved")
		vim.wait(10)

		-- Trigger sync
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Get extmarks again after deletion
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		
		-- All marks should still exist
		assert.equals(4, #extmarks, "All 4 extmarks should still exist after deletion")

		-- Assert that all marks have empty content (all "h" characters should be deleted)
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("", content_str, string.format("Extmark %d should have empty content after x deletion", i))
		end
	end)

	it("should sync marks after word deletion and subsequent insertions", function()
		local buf = vim.api.nvim_get_current_buf()

		-- Create buffer with three "hello" words
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello",
			"hello",
			"hello",
		})

		-- Place cursor at beginning of first "hello" and select word in normal mode
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		-- Select all "hello" occurrences in normal mode
		viedit.toggle_all()
		vim.wait(10)

		-- Verify we have 3 extmarks
		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Verify initial content
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("hello", content_str, string.format("Extmark %d should initially have 'hello'", i))
		end

		-- Place cursor at beginning of first "hello" and delete the word
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("dw")
		vim.wait(10)

		-- Simulate real-world scenario: CursorMoved fires before TextChanged
		vim.cmd("doautocmd CursorMoved")
		vim.wait(10)

		-- Trigger sync
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Get extmarks again after deletion
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "All 3 extmarks should still exist after deletion")

		-- Assert that all marks are still there but their content is empty
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("", content_str, string.format("Extmark %d should have empty content after deletion", i))
		end

		-- Insert 1 character
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("ix<Esc>")
		vim.wait(10)

		-- Trigger sync
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Get extmarks and verify all have the single character
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "All 3 extmarks should still exist")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("x", content_str, string.format("Extmark %d should have content 'x'", i))
		end

		-- Add another character
		vim.api.nvim_win_set_cursor(0, { 1, 1 })
		feedkeys("ay<Esc>")
		vim.wait(10)

		-- Trigger sync
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Get extmarks and verify all have both characters
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "All 3 extmarks should still exist")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("xy", content_str, string.format("Extmark %d should have content 'xy'", i))
		end
	end)
end)
