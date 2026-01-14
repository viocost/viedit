-- Logging utility for debugging extmark behavior
local M = {}
local Marks = require("viedit.marks")

local function get_log_file_path(buffer_id)
	local timestamp = os.date("%Y%m%d_%H%M%S")
	return string.format("/tmp/viedit_%s_buf%d.log", timestamp, buffer_id)
end

function M.create_log_file(buffer_id)
	local log_path = get_log_file_path(buffer_id)
	local file = io.open(log_path, "w")
	if file then
		file:write(string.format("=== Viedit Session Started at %s ===\n", os.date("%Y-%m-%d %H:%M:%S")))
		file:write(string.format("Buffer: %d\n\n", buffer_id))
		file:close()
	end
	return log_path
end

function M.log_extmark_creation(log_path, extmark_id, start_row, start_col, end_row, end_col, right_gravity, end_right_gravity)
	local file = io.open(log_path, "a")
	if file then
		file:write(string.format("EXTMARK CREATED: id=%d, start=[%d,%d], end=[%d,%d], right_gravity=%s, end_right_gravity=%s\n",
			extmark_id, start_row, start_col, end_row, end_col,
			tostring(right_gravity), tostring(end_right_gravity)))
		file:close()
	end
end

function M.log_action(log_path, action, buffer_id, namespace_ns, session)
	local file = io.open(log_path, "a")
	if not file then
		return
	end
	
	file:write("\n" .. string.rep("=", 80) .. "\n")
	file:write(string.format("ACTION: %s at %s\n", action, os.date("%H:%M:%S")))
	
	-- Get all extmarks
	local extmarks = Marks.get_all_with_details(buffer_id, namespace_ns)
	file:write(string.format("Number of extmarks: %d\n", #extmarks))
	
	if session then
		file:write(string.format("Current extmark: %s\n", tostring(session.current_extmark)))
		file:write(string.format("Insert mode extmark: %s\n", tostring(session.insert_mode_extmark)))
		file:write(string.format("Current selection: '%s'\n", session.current_selection))
	end
	
	-- Get cursor position
	local cursor = vim.api.nvim_win_get_cursor(0)
	file:write(string.format("Cursor position: [%d,%d]\n", cursor[1] - 1, cursor[2]))
	
	-- Log each extmark
	for i, mark in ipairs(extmarks) do
		local mark_id = mark[1]
		local start_row = mark[2]
		local start_col = mark[3]
		local details = mark[4]
		
		-- Get content
		local content = ""
		if details.end_row then
			local lines = vim.api.nvim_buf_get_text(buffer_id, start_row, start_col, details.end_row, details.end_col, {})
			content = table.concat(lines, "\\n")
		end
		
		file:write(string.format("  Extmark %d: id=%d, start=[%d,%d], end=[%d,%d], right_gravity=%s, end_right_gravity=%s, content='%s'\n",
			i, mark_id, start_row, start_col,
			details.end_row or start_row, details.end_col or start_col,
			tostring(details.right_gravity), tostring(details.end_right_gravity),
			content))
	end
	
	-- Log buffer content
	local lines = vim.api.nvim_buf_get_lines(buffer_id, 0, -1, false)
	file:write("Buffer content:\n")
	for i, line in ipairs(lines) do
		file:write(string.format("  Line %d: '%s'\n", i - 1, line))
	end
	
	file:close()
end

function M.log_session_end(log_path)
	local file = io.open(log_path, "a")
	if file then
		file:write("\n" .. string.rep("=", 80) .. "\n")
		file:write(string.format("=== Session Ended at %s ===\n", os.date("%Y-%m-%d %H:%M:%S")))
		file:close()
	end
	
	print(string.format("[Viedit] Session log saved to: %s", log_path))
end

return M
