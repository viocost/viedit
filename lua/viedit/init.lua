require('viedit.namespace')

local M = {}
local core = require('viedit.core')

local config = require('viedit.config')
local Marks = require('viedit.marks')
local keymaps = require('viedit.keymaps')

M.setup = config.setup

local function disable_session(buffer_id)
  if core.is_session_active(buffer_id) then
    core.deselect_all(buffer_id)
    core.close_session(buffer_id)
    keymaps.restore_original_keymaps(buffer_id)
  end
end

-- Toggles selection of all occurrences of the word under the cursor in the buffer.
-- In _normal_ mode, it selects only independent keyword occurrences.
-- This means substrings within larger words are not selected.
-- In _visual_ mode, it selects all substrings, regardless of keyword boundaries.
-- If any occurrences are already selected, the function will deselect everything and end the session.
function M.toggle_all()
  local buffer_id = vim.api.nvim_get_current_buf()
  local select = require('viedit.select')

  if core.is_session_active(buffer_id) then
    disable_session(buffer_id)
  else
    local text = select.get_text_under_cursor(buffer_id)

    if text then
      local lock_to_keyword = vim.fn.mode() == 'n'
      local session = core.start_session(buffer_id)
      keymaps.set_viedit_keymaps(buffer_id)

      core.select_all(buffer_id, text, session, lock_to_keyword)
      Marks.highlight_current_extmark(buffer_id, session)
      session.current_selection = text
    end
    vim.cmd.norm({ '\x1b', bang = true })
  end
end

-- Toggles the selection of a single occurrence.
-- If the cursor is inside a selected occurrence, this function will deselect it.
-- If the cursor is on non-selected text that matches the selected text, this function will select it.
-- If the text under the cursor does not match the selected text, the function will do nothing.
function M.toggle_single()
  local buffer_id = vim.api.nvim_get_current_buf()

  core.toggle_single(buffer_id)
end

-- Jumps to the next or previous selected occurrence.
-- Pass {back=true} to traverse backward.
function M.step(opts)
  opts = opts or {}
  core.navigate_extmarks(opts.back)
end

-- This is for development to hot-reload the plugin
function M.reload()
  local plugin_namespace = 'viedit'

  for name, _ in pairs(package.loaded) do
    if name:match('^' .. plugin_namespace) then
      package.loaded[name] = nil
    end
  end

  dofile(vim.fn.stdpath('config') .. '/init.lua')
  print('Viedit reloaded')
end

M.restrict_to_function = core.restrict_to_function
M.restrict_to_visual_selection = core.restrict_to_visual_selection
M.disable = function()
  disable_session(vim.api.nvim_get_current_buf())
end
return M
