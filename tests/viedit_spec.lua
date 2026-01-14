-- Unit tests for viedit plugin
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

describe("viedit", function()
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

	describe("toggle_all in normal mode", function()
		it("should select all keyword occurrences", function()
			local buf = vim.api.nvim_get_current_buf()
			
			-- Set buffer content
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
				"hello",
				"hello",
				"world"
			})
			
			-- Place cursor on first "hello" (line 1, col 0)
			vim.api.nvim_win_set_cursor(0, {1, 0})
			
			-- Ensure we're in normal mode
			vim.cmd("normal! \\<Esc>")
			
			-- Trigger toggle_all
			viedit.toggle_all()
			
			-- Assert session is active
			assert.is_true(Session.is_active(buf), "Session should be active")
			
			-- Get all extmarks in our namespace
			local extmarks = vim.api.nvim_buf_get_extmarks(
				buf,
				namespace.ns,
				0,
				-1,
				{ details = true }
			)
			
			-- Should have exactly 2 extmarks (two "hello" occurrences)
			assert.equals(2, #extmarks, "Should have 2 extmarks for 2 'hello' occurrences")
			
			-- Verify first extmark
			local mark1 = extmarks[1]
			assert.equals(0, mark1[2], "First mark should be on row 0")
			assert.equals(0, mark1[3], "First mark should start at col 0")
			assert.equals(0, mark1[4].end_row, "First mark should end on row 0")
			assert.equals(5, mark1[4].end_col, "First mark should end at col 5")
			
			-- Verify second extmark
			local mark2 = extmarks[2]
			assert.equals(1, mark2[2], "Second mark should be on row 1")
			assert.equals(0, mark2[3], "Second mark should start at col 0")
			assert.equals(1, mark2[4].end_row, "Second mark should end on row 1")
			assert.equals(5, mark2[4].end_col, "Second mark should end at col 5")
			
			-- Verify content of both extmarks
			local content1 = vim.api.nvim_buf_get_text(
				buf,
				mark1[2],
				mark1[3],
				mark1[4].end_row,
				mark1[4].end_col,
				{}
			)
			local content2 = vim.api.nvim_buf_get_text(
				buf,
				mark2[2],
				mark2[3],
				mark2[4].end_row,
				mark2[4].end_col,
				{}
			)
			
			assert.equals("hello", content1[1], "First extmark content should be 'hello'")
			assert.equals("hello", content2[1], "Second extmark content should be 'hello'")
			assert.are.same(content1, content2, "Both extmarks should have identical content")
		end)
		
		it("should not select substrings in normal mode", function()
			local buf = vim.api.nvim_get_current_buf()
			
			-- Set buffer content with "hello" and "helloworld"
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
				"hello",
				"helloworld",
				"hello"
			})
			
			-- Place cursor on first "hello"
			vim.api.nvim_win_set_cursor(0, {1, 0})
			vim.cmd("normal! \\<Esc>")
			
			-- Trigger toggle_all
			viedit.toggle_all()
			
			-- Get all extmarks
			local extmarks = vim.api.nvim_buf_get_extmarks(
				buf,
				namespace.ns,
				0,
				-1,
				{ details = true }
			)
			
			-- Should have exactly 2 extmarks (not including "helloworld")
			assert.equals(2, #extmarks, "Should only select standalone 'hello' keywords")
		end)
	end)

	describe("toggle_all in visual mode", function()
		it("should select all substring occurrences", function()
			local buf = vim.api.nvim_get_current_buf()
			
			-- Set buffer content
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
				"hello",
				"helloworld",
				"hello"
			})
			
			-- Simulate visual selection of "hello" on first line
			vim.api.nvim_win_set_cursor(0, {1, 0})
			
			-- Enter visual mode and select "hello"
			vim.cmd("normal! v4l")
			
			-- Trigger toggle_all in visual mode
			viedit.toggle_all()
			
			-- Get all extmarks
			local extmarks = vim.api.nvim_buf_get_extmarks(
				buf,
				namespace.ns,
				0,
				-1,
				{ details = true }
			)
			
			-- Should have 3 extmarks (all "hello" substrings)
			assert.equals(3, #extmarks, "Should select all 'hello' substrings including in 'helloworld'")
		end)
	end)

	describe("multi-line selection", function()
		it("should select multi-line patterns", function()
			local buf = vim.api.nvim_get_current_buf()
			
			-- Set buffer content with multi-line patterns
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
				"hello",
				"world",
				"",
				"hello",
				"world",
				"",
				"other"
			})
			
			-- Simulate visual selection of "hello\nworld" (lines 1-2)
			vim.api.nvim_win_set_cursor(0, {1, 0})
			vim.cmd("normal! vj$")
			
			-- Trigger toggle_all in visual mode
			viedit.toggle_all()
			
			-- Get all extmarks
			local extmarks = vim.api.nvim_buf_get_extmarks(
				buf,
				namespace.ns,
				0,
				-1,
				{ details = true }
			)
			
			-- Should have 2 extmarks (two "hello\nworld" patterns)
			assert.equals(2, #extmarks, "Should have 2 multi-line extmarks")
			
			-- Verify first extmark spans two lines
			local mark1 = extmarks[1]
			assert.equals(0, mark1[2], "First mark should start on row 0")
			assert.equals(1, mark1[4].end_row, "First mark should end on row 1")
			
			-- Verify second extmark spans two lines
			local mark2 = extmarks[2]
			assert.equals(3, mark2[2], "Second mark should start on row 3")
			assert.equals(4, mark2[4].end_row, "Second mark should end on row 4")
			
			-- Verify content
			local content1 = vim.api.nvim_buf_get_text(
				buf,
				mark1[2],
				mark1[3],
				mark1[4].end_row,
				mark1[4].end_col,
				{}
			)
			local content2 = vim.api.nvim_buf_get_text(
				buf,
				mark2[2],
				mark2[3],
				mark2[4].end_row,
				mark2[4].end_col,
				{}
			)
			
			local content1_str = table.concat(content1, "\n")
			local content2_str = table.concat(content2, "\n")
			
			assert.equals("hello\nworld", content1_str, "First extmark should contain 'hello\\nworld'")
			assert.equals(content1_str, content2_str, "Both multi-line extmarks should have identical content")
		end)
	end)
end)
