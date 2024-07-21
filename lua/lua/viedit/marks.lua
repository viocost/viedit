local ExtMarks = {}
ExtMarks.__index = ExtMarks

function ExtMarks.new()
	local self = setmetatable({}, ExtMarks)
	self.set = {}
	return self
end

function ExtMarks.from_ids(ids)
	local self = ExtMarks.new()
	for _, id in ipairs(ids) do
		self.set[id] = true
	end
	return self
end

function ExtMarks:add(extmark)
	self.set[extmark] = true
end

function ExtMarks:delete(extmark)
	self.set[extmark] = nil
end

function ExtMarks:contains(extmark)
	return self.set[extmark] ~= nil
end

function ExtMarks:get_all()
	local extmarks = {}
	for key, _ in pairs(self.set) do
		table.insert(extmarks, key)
	end
	return extmarks
end

function ExtMarks:get_all_reversed()
	local extmarks = {}
	for key, _ in pairs(self.set) do
		table.insert(extmarks, key)
	end
	table.sort(extmarks, function(a, b)
		return a > b
	end) -- Sort in descending order
	return extmarks
end

function ExtMarks:size()
	return #vim.tbl_keys(self.set)
end

function ExtMarks:clear()
	self.set = {}
end

return ExtMarks
