-- Change operations tests for viedit (c, C, cc)
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit change operations", function()
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

	it("should sync 'c' (change) operation within extmark", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"foo hello bar",
			"hello end",
		})

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Position at start of first extmark and change 2 characters
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("c2lXY<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("XYllo", content_str, string.format("Extmark %d should be 'XYllo'", i))
		end
	end)

	it("should sync 'cc' (change line) operation", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello",
			"hello",
			"hello",
		})

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Change entire line
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("ccworld<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("world", content_str, string.format("Extmark %d should be 'world'", i))
		end
	end)

	it("should sync 'C' (change to end of line) operation", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"hello test",
			"hello end",
		})

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		-- Position in middle of first extmark and change to end
		vim.api.nvim_win_set_cursor(0, { 1, 2 })
		feedkeys("CXY<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("heXY", content_str, string.format("Extmark %d should be 'heXY'", i))
		end
	end)

	it("should sync 'cw' (change word) operation", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world",
			"foo hello bar",
			"hello end",
		})

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should have 3 'hello' occurrences")

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("cwgoodbye<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("goodbye", content_str, string.format("Extmark %d should be 'goodbye'", i))
		end
	end)
end)
