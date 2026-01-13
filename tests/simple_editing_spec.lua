-- Simple editing tests for viedit
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

-- Helper to execute normal mode commands with proper key code translation
local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, 'x', false)
end

describe("viedit simple editing", function()
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

	it("should sync inserted letter to all occurrences", function()
		local buf = vim.api.nvim_get_current_buf()
		
		-- Create buffer with 7 "hello" words mixed with other words
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"hello world and hello",
			"foo hello bar",
			"hello something else",
			"random hello text",
			"hello again",
			"final hello here"
		})
		
		-- Place cursor on first "hello" and select all in normal mode
		vim.api.nvim_win_set_cursor(0, {1, 0})
		feedkeys("<Esc>")
		vim.wait(10)
		
		viedit.toggle_all()
		vim.wait(10)
		
		-- Verify we have 7 extmarks
		local extmarks = vim.api.nvim_buf_get_extmarks(
			buf,
			namespace.ns,
			0,
			-1,
			{ details = true }
		)
		assert.equals(7, #extmarks, "Should have 7 'hello' occurrences")
		
		-- Go to the first extmark and enter insert mode at the beginning
		vim.api.nvim_win_set_cursor(0, {1, 0})  -- Start of "hello"
		feedkeys("ix")  -- Insert 'x' at beginning
		vim.wait(10)
		feedkeys("<Esc>")  -- Exit insert mode
		
		-- Manually trigger the autocmd since it might not fire in test environment
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)  -- Wait for sync
		
		-- Check session state
		local session = Session.get(buf)
		print("Session active:", Session.is_active(buf))
		print("Current extmark:", session and session.current_extmark or "nil")
		print("Current selection:", session and session.current_selection or "nil")
		
		-- Check what's actually in the buffer
		local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
		print("First line content:", first_line)
		
		-- Check the first extmark's range
		local first_extmark = vim.api.nvim_buf_get_extmark_by_id(buf, namespace.ns, 1, { details = true })
		print("First extmark range:", vim.inspect(first_extmark))
		
		-- Get all extmarks and check their content
		extmarks = vim.api.nvim_buf_get_extmarks(
			buf,
			namespace.ns,
			0,
			-1,
			{ details = true }
		)
		
		-- Verify all extmarks have the updated content "xhello"
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(
				buf,
				mark[2],
				mark[3],
				mark[4].end_row,
				mark[4].end_col,
				{}
			)
			local content_str = table.concat(content, "\n")
			assert.equals(
				"xhello",
				content_str,
				string.format("Extmark %d should have content 'xhello' but got '%s'", i, content_str)
			)
		end
		
		-- Verify buffer content shows all changes
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.is_true(lines[1]:match("xhello world and xhello") ~= nil, "First line should have 'xhello'")
		assert.is_true(lines[2]:match("foo xhello bar") ~= nil, "Second line should have 'xhello'")
		assert.is_true(lines[3]:match("xhello something") ~= nil, "Third line should have 'xhello'")
	end)
end)
