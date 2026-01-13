-- Append edge case tests for viedit
-- Testing appending at the END of extmarks (gravity edge case)
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit append at end of extmark", function()
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

	it("should sync append at end of extmark in normal mode", function()
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

		-- Position cursor at END of first "hello" (after 'o')
		vim.api.nvim_win_set_cursor(0, { 1, 5 }) -- Column 5 is after the last character
		feedkeys("aXY<Esc>") -- Append 'XY' at the end
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Verify all extmarks have been updated
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("helloXY", content_str, string.format("Extmark %d should be 'helloXY'", i))
		end

		-- Verify buffer content
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.equals("helloXY", lines[1], "First line should be 'helloXY'")
		assert.equals("helloXY", lines[4], "Fourth line should be 'helloXY'")
		assert.equals("helloXY", lines[7], "Seventh line should be 'helloXY'")
	end)

	it("should sync append at end of extmark in visual mode", function()
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

		-- Position cursor at END of first "hello" and append
		vim.api.nvim_win_set_cursor(0, { 1, 5 })
		feedkeys("aXY<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		-- Verify all extmarks have been updated
		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("helloXY", content_str, string.format("Extmark %d should be 'helloXY'", i))
		end
	end)

	it("should sync append at end with multiple characters", function()
		local buf = vim.api.nvim_get_current_buf()

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

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Append multiple times
		vim.api.nvim_win_set_cursor(0, { 1, 5 })
		feedkeys("a123<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("hello123", content_str, string.format("Extmark %d should be 'hello123'", i))
		end
	end)
end)
