M = {}

function M.get_current_function_range()
  if not pcall(require, 'nvim-treesitter') then
    print('Treesitter is not available')
    return nil
  end

  local buffer_id = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_range = { cursor[1] - 1, cursor[2] }

  local parser = vim.treesitter.get_parser(buffer_id)
  if not parser then
    print('No parser available for the current buffer')
    return nil
  end

  local root = parser:parse()[1]:root()

  local node = root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])

  while node do
    if node:type():match('function') or node:type():match('method') then
      local start_row, start_col, end_row, end_col = node:range()
      return {
        start = { start_row + 1, start_col },
        ['end'] = { end_row + 1, end_col },
      }
    end
    node = node:parent()
  end

  return nil
end

function M.get_visual_selection_range()
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
    print('Not in visual mode')
    return nil
  end

  local pos_start = vim.fn.getpos('v')
  local pos_end = vim.fn.getpos('.')

  local start_row = pos_start[2]
  local start_col = pos_start[3] - 1
  local end_row = pos_end[2]
  local end_col = pos_end[3] - 1

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  return {
    start = { start_row, start_col },
    ['end'] = { end_row, end_col },
  }
end

return M
