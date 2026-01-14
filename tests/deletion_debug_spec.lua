-- Debug test to see what happens with deletions
local viedit = require("viedit")
local namespace = require("viedit.namespace")
local Session = require("viedit.session")

local function feedkeys(keys)
	local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "x", false)
end

describe("viedit deletion debugging", function()
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

	it("debug: check state after x deletion", function()
		local buf = vim.api.nvim_get_current_buf()

		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"h",
			"h",
			"h",
		})

		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("<Esc>")
		vim.wait(10)

		viedit.toggle_all()
		vim.wait(10)

		local session = Session.get(buf)
		
		print("BEFORE DELETION:")
		print("  current_extmark:", session.current_extmark)
		print("  insert_mode_extmark:", session.insert_mode_extmark)
		print("  current_selection:", session.current_selection)
		
		local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		print("  Number of extmarks:", #extmarks)
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			print(string.format("  Extmark %d content: '%s'", i, table.concat(content, "\n")))
		end

		-- Delete with x
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		feedkeys("x")
		vim.wait(10)

		print("\nAFTER X (before any autocmds):")
		print("  current_extmark:", session.current_extmark)
		
		-- Simulate CursorMoved firing BEFORE TextChanged (real-world scenario)
		vim.cmd("doautocmd CursorMoved")
		vim.wait(10)
		
		print("\nAFTER CursorMoved (before TextChanged):")
		print("  current_extmark:", session.current_extmark)
		print("  insert_mode_extmark:", session.insert_mode_extmark)
		print("  current_selection:", session.current_selection)
		
		-- Check buffer state
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		print("  Buffer lines:", vim.inspect(lines))

		-- Trigger sync manually
		vim.cmd("doautocmd TextChanged")
		vim.wait(100)

		print("\nAFTER TextChanged:")
		print("  current_extmark:", session.current_extmark)
		print("  insert_mode_extmark:", session.insert_mode_extmark)
		print("  current_selection:", session.current_selection)

		extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace.ns, 0, -1, { details = true })
		print("  Number of extmarks:", #extmarks)
		for i, mark in ipairs(extmarks) do
			local content = vim.api.nvim_buf_get_text(buf, mark[2], mark[3], mark[4].end_row, mark[4].end_col, {})
			print(string.format("  Extmark %d content: '%s'", i, table.concat(content, "\n")))
		end

		-- Check buffer state again
		lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		print("  Buffer lines:", vim.inspect(lines))
	end)
end)
