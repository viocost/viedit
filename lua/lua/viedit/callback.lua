M = {}
local util = require("viedit/util")

function M.on_text_changed(buffer_id, ev)
	print("Text changed in ", buffer_id, ev.event)
end

function M.on_cursor_move(buffer_id, session)
	util.highlight_current_extrmark(buffer_id, session)
end

return M
