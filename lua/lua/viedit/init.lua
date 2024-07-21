M = {}
require("viedit.namespace")

local core = require("viedit.core")

local config = require("viedit.config")
local util = require("viedit/util")
local constants = require("viedit/constants")
local keymaps = require("viedit/keymaps")

local function bootstrap()
	local cfg = config.config
	vim.api.nvim_set_hl(0, constants.HL_GROUP_SELECT, cfg.highlight)
	vim.api.nvim_set_hl(0, constants.HL_GROUP_SELECT_CURRENT, cfg.current_highlight)
end

function M.setup(opts)
	config.config = vim.tbl_deep_extend("force", config.config, opts or {})
end

function M.toggle_all()
	print("Toggle all called")
	local buffer_id = vim.api.nvim_get_current_buf()
	local select = require("viedit/select")

	if core.is_session_active(buffer_id) then
		core.deselect_all(buffer_id)
		core.close_session(buffer_id)
		keymaps.restore_original_keymaps(buffer_id)
	else
		local text = select.get_text_under_cursor(buffer_id)
		print("Text to select is", text)

		if text then
			local lock_to_keyword = vim.fn.mode() == "n"
			local session = core.start_session(buffer_id)
			keymaps.set_viedit_keymaps(buffer_id)

			core.select_all(buffer_id, text, session, lock_to_keyword)
			util.highlight_current_extrmark(buffer_id, session)
			session.current_selection = text
		end

		vim.cmd.norm({ "\x1b", bang = true })
	end
end

function M.toggle_single()
	local buffer_id = vim.api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line = cursor_pos[1]
	local col = cursor_pos[2]

	if not core.is_session_active(buffer_id) then
		print("Not yet implemented")
		return
	end

	core.toggle_single(buffer_id)
end

function M.step(opts)
	opts = opts or {}
	core.navigate_extmarks(opts.back)
end

function M.reload()
	local plugin_namespace = "viedit"

	for name, _ in pairs(package.loaded) do
		if name:match("^" .. plugin_namespace) then
			package.loaded[name] = nil
		end
	end

	dofile(vim.fn.stdpath("config") .. "/init.lua")
	print("Viedit reloaded")
end

M.restrict_to_function = core.restrict_to_function

vim.api.nvim_create_autocmd("VimEnter", {
	callback = bootstrap,
	once = true,
})

return M
