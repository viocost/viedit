-- Delete word edge case tests for viedit
-- Testing dw followed by re-insertion
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit delete word and re-insert", function()
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

	it("should handle dw and re-insert in normal mode", function()
		local buf = vim.api.nvim_get_current_buf()

		-- Create buffer with multiple "hello\nworld" pairs
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello",
			"world",
			"",
			"hello",
			"world",
			"",
			"hello",
			"world",
		})

		-- Select all "hello" in normal mode
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Position cursor at beginning of first "hello" and delete word
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("dw")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Verify extmarks still exist (they should be zero-width now)
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks after deletion")

		-- Verify extmarks are empty (zero-width)
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("", content_str, string.format("Extmark %d should be empty after dw", i))
		end

		-- Now insert new text at the beginning
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("igoodbye<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Verify all extmarks now contain the new text
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("goodbye", content_str, string.format("Extmark %d should be 'goodbye'", i))
		end

		-- Verify buffer content
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.equals("goodbye", lines[1], "First line should be 'goodbye'")
		assert.equals("goodbye", lines[4], "Fourth line should be 'goodbye'")
		assert.equals("goodbye", lines[7], "Seventh line should be 'goodbye'")
	end)

	it("should handle dw and re-insert in visual mode", function()
		local buf = vim.api.nvim_get_current_buf()

		-- Create buffer with multiple "hello\nworld" pairs
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello",
			"world",
			"",
			"hello",
			"world",
			"",
			"hello",
			"world",
		})

		-- Select "hello" in visual mode
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)
		
		-- Visual select "hello"
		feedkeys("viw")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Delete word
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("dw")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Verify extmarks still exist and are empty
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks after deletion")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("", content_str, string.format("Extmark %d should be empty after dw", i))
		end

		-- Insert new text
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("iNEW<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Verify sync
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("NEW", content_str, string.format("Extmark %d should be 'NEW'", i))
		end
	end)

	it("should handle multiple delete-insert cycles", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello",
			"world",
			"",
			"hello",
			"world",
		})

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(2, #extmarks, "Should have 2 'hello' occurrences")

		-- First cycle: delete and insert "AAA"
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("dwiAAA<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			assert.equals("AAA", table.concat(content, "\n"))
		end

		-- Second cycle: delete again and insert "BBB"
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("dwiBBB<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			assert.equals("BBB", table.concat(content, "\n"))
		end
	end)
end)
