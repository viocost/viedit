-- Visual block mode tests for viedit
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit visual block mode", function()
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

	it("should sync visual block insert across extmarks", function()
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

		-- Visual block select first 2 characters of each "hello"
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<C-v>ljjIX<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		-- All should have 'X' prepended
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("Xhello", content_str, string.format("Extmark %d should be 'Xhello'", i))
		end
	end)

	it("should sync visual block delete across extmarks", function()
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

		-- Visual block select and delete first 2 characters
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<C-v>ljjd")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		-- All should have first 2 characters deleted
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("llo", content_str, string.format("Extmark %d should be 'llo'", i))
		end
	end)

	it("should sync visual block change across extmarks", function()
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

		-- Visual block change first 2 characters
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<C-v>ljjcXY<Esc>")
		vim.wait(10)
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		assert.equals(3, #extmarks, "Should still have 3 extmarks")

		-- All should have first 2 characters changed
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			local content_str = table.concat(content, "\n")
			assert.equals("XYllo", content_str, string.format("Extmark %d should be 'XYllo'", i))
		end
	end)
end)
