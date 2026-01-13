-- Test extmark behavior with deletions
-- This helps understand how extmarks react to text changes

local buf = vim.api.nvim_get_current_buf()
local ns = vim.api.nvim_create_namespace("test_deletion")

-- Create a simple multi-line text
local lines = {"hello", "world"}
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"hello", "world", "", "hello", "world"})

-- Create a multi-line extmark
local mark1 = vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    end_row = 1,
    end_col = 5,
    right_gravity = false,
    end_right_gravity = true
})

print("Mark created:", mark1)
print("Initial extmark position:")
local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, mark1, {details = true})
print(vim.inspect(pos))

-- What happens with different gravity settings?
print("\nright_gravity=false means: start stays fixed when inserting AT the start")
print("end_right_gravity=true means: end moves with text when inserting AT the end")
