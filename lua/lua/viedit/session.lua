local Session = {}
Session.__index = Session

local sessions = {} -- Private table to store all sessions

local ExtMarks = require("viedit.marks")

function Session.new(buffer_id, augroup_id)
	local session = setmetatable({
		buffer_id = buffer_id,
		augroup_id = augroup_id,
		marks = ExtMarks.new(),
		current_selection = "",
		current_extmark = nil,
		is_active = true,
		last_activity = os.time(),
	}, Session)
	sessions[buffer_id] = session
	return session
end

-- Public API

function Session.get(buffer_id)
	return sessions[buffer_id]
end

function Session:set_current_extmark(extmark_id)
	print("Setting current extmark to", extmark_id)
	self.current_extmark = extmark_id
end

function Session.is_active(buffer_id)
	local session = sessions[buffer_id]
	return session and session.is_active or false
end

function Session.activate(buffer_id)
	local session = sessions[buffer_id]
	if session then
		session.is_active = true
		session.last_activity = os.time()
	else
		Session.new(buffer_id)
	end
end

function Session:deactivate()
	self.is_active = false
end

function Session.delete(buffer_id)
	sessions[buffer_id] = nil
end

function Session.update_marks(buffer_id, new_marks)
	local session = sessions[buffer_id]
	if session then
		session.marks = new_marks
		session.last_activity = os.time()
	end
end

function Session.get_marks(buffer_id)
	local session = sessions[buffer_id]
	return session and session.marks:get_all()
end

return Session
