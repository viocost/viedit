M = {}
local keys = require("viedit/config").config.keys

function M.set_viedit_keymaps(buffer_id)
	-- Store original mappings for specific keys
	M.original_keymaps = {}
	local keys_to_override = { keys.next_occurrence, keys.previous_occurrence, "t" }
	for _, key in ipairs(keys_to_override) do
		local existing_keymap = vim.api.nvim_buf_get_keymap(buffer_id, "n")[key]
		if existing_keymap and #existing_keymap > 0 then
			M.original_keymaps[key] = existing_keymap[1]
		end
	end

	-- Set new mappings for 'n' and 'N'
	vim.api.nvim_buf_set_keymap(
		buffer_id,
		"n",
		keys.next_occurrence,
		[[<cmd>lua require'viedit'.step()<CR>]],
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		buffer_id,
		"n",
		keys.previous_occurrence,
		[[<cmd>lua require'viedit'.step({back = true})<CR>]],
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		buffer_id,
		"n",
		"t",
		[[<cmd>lua require'viedit'.toggle_single()<CR>]],
		{ noremap = true, silent = true }
	)
end

function M.restore_original_keymaps(buffer_id)
	-- Clear iedit-specific mappings
	vim.api.nvim_buf_del_keymap(buffer_id, "n", keys.next_occurrence)
	vim.api.nvim_buf_del_keymap(buffer_id, "n", keys.previous_occurrence)

	-- Restore original mappings for specific keys
	for key, keymap in pairs(M.original_keymaps) do
		vim.api.nvim_buf_set_keymap(buffer_id, "n", key, keymap.rhs or "", {
			silent = keymap.silent == 1,
			noremap = keymap.noremap == 1,
			expr = keymap.expr == 1,
			nowait = keymap.nowait == 1,
		})
	end

	-- Clear the stored original keymaps
	M.original_keymaps = {}
end

return M
