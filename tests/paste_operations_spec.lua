-- Paste operations tests for viedit (p, P)
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit paste operations", function()
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

	it("should sync 'p' (paste after) in normal mode", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"foo hello bar",
			"hello end",
		})

		-- Copy text to register
		vim.fn.setreg('"', "XY")

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Paste after first character
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("p")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("hXYello", content_str, string.format("Extmark %d should be 'hXYello'", i))
		end
	end)

	it("should sync 'P' (paste before) in normal mode", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"foo hello bar",
			"hello end",
		})

		-- Copy text to register
		vim.fn.setreg('"', "XY")

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Paste before cursor
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("P")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("XYhello", content_str, string.format("Extmark %d should be 'XYhello'", i))
		end
	end)

	it("should sync paste in middle of extmark", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"foo hello bar",
			"hello end",
		})

		vim.fn.setreg('"', "XY")

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Position in middle and paste
		vim.api.nvim_win_set_cursor(0, { 1, 2 })
		feedkeys("p")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("helXYlo", content_str, string.format("Extmark %d should be 'helXYlo'", i))
		end
	end)

	it("should sync multi-line paste", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"foo hello bar",
			"hello end",
		})

		-- Copy multi-line text to register
		vim.fn.setreg('"', "X\nY")

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Paste multi-line after first character
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("p")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		-- Each extmark should now contain multi-line content
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("hX\nYello", content_str, string.format("Extmark %d should be 'hX\\nYello'", i))
		end
	end)

	it("should sync visual mode paste", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"foo hello bar",
			"hello end",
		})

		vim.fn.setreg('"', "REPLACED")

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Visual select first 2 characters and paste over them
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("vlp")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("REPLACEDllo", content_str, string.format("Extmark %d should be 'REPLACEDllo'", i))
		end
	end)
end)
