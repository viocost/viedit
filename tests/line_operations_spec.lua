-- Line operations tests for viedit (joining and splitting)
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit line operations", function()
	before_each(function()
		-- Create a new buffer for each test
		vim.cmd("enew!")
		local buf = vim.api.nvim_get_current_buf()

		-- Clear any existing sessions
		if Session.is_active(buf) then
			viedit.disable()
		end
	end)

	after_each(function()
		-- Clean up after each test
		local buf = vim.api.nvim_get_current_buf()
		if Session.is_active(buf) then
			viedit.disable()
		end
	end)

	it("should sync line splitting (Enter) within extmark to all occurrences", function()
		local buf = vim.api.nvim_get_current_buf()

		-- Create buffer with 3 "hello" words
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"foo hello bar",
			"hello end",
		})

		-- Select all "hello" occurrences
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		-- Verify we have 3 extmarks
		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Position cursor in middle of first "hello" (between 'l' and 'l')
		vim.api.nvim_win_set_cursor(0, { 1, 3 })
		feedkeys("i<CR><Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Check that all occurrences have been split
		-- Each "hello" should become "hel\nlo"
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("hel\nlo", content_str, string.format("Extmark %d should be 'hel\\nlo'", i))
		end
	end)

	it("should handle line splitting across multiple extmarks", function()
		local buf = vim.api.nvim_get_current_buf()

		-- Create buffer where line has multiple occurrences
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world hello end hello final",
		})

		-- Select all "hello"
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Split first "hello" in middle
		vim.api.nvim_win_set_cursor(0, { 1, 3 })
		feedkeys("i<CR><Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- All should be split
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		-- Verify buffer has correct structure
		-- The splits happen at the same position in each extmark, so we should have:
		-- Line 1: "hel" (from first hello split)
		-- Line 2: "lo world hel" (lo from first + second hello split)
		-- Line 3: "lo end hel" (lo from second + third hello split)
		-- Line 4: "lo final" (lo from third)
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.equals(4, #lines, "Should have 4 lines after all splits")
		
		-- All extmarks should contain split text
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("hel\nlo", content_str, string.format("Extmark %d should be split", i))
		end
	end)
end)
