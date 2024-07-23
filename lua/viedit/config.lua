local M = {}
local constants = require("viedit.constants")

---@class VieditOptions
M.defaults = {
	-- Highlight group for marked text
	-- Can use any highlight group definitions
	highlight = {

		fg = "#000000",
		bg = "#fff98c",
	},

	-- Highlight group for the marked text where cursor currently is
	current_highlight = {
		link = "CurSearch",
	},

	-- Determines the behavior of the end of the mark when text is inserted
	-- true: the end of the mark stays at its position (moves with inserted text)
	-- false: the end of the mark moves as text is inserted
	end_right_gravity = true,

	-- Determines the behavior of the start of the mark when text is inserted
	-- true: the start of the mark stays at its position (moves with inserted text)
	-- false: the start of the mark remains fixed as text is inserted
	right_gravity = false,

	-- It may be useful to keep semantics of next/previous keys
	-- If this is true, default mappings for specified keys will be overriden
	-- to do iedit operations
	-- true: use the plugin's key mappings
	-- false: use default Vim/Neovim key mappings
	override_keys = true,

	-- Defines keys that will be overriden and mapped to viedit operations
	-- If override_keys is off - this won't be applied
	keys = {
		-- Key to move to the next occurrence of the marked text
		next_occurrence = "n",
		-- Key to move to the previous occurrence of the marked text
		previous_occurrence = "N",
	},
}

---@type VieditOptions
M.config = vim.deepcopy(M.defaults)

M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})

	vim.api.nvim_set_hl(0, constants.HL_GROUP_SELECT, M.config.highlight)
	vim.api.nvim_set_hl(0, constants.HL_GROUP_SELECT_CURRENT, M.config.current_highlight)
end

return M
