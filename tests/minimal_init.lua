-- Minimal init.lua for running tests
-- This sets up the minimal environment needed for testing

-- Add the plugin to runtimepath
vim.opt.runtimepath:append(".")

-- Add plenary to runtimepath if available
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 1 then
	vim.opt.runtimepath:append(plenary_path)
end

-- Set up basic vim options
vim.opt.swapfile = false
vim.opt.hidden = true

-- Load the plugin
require("viedit")
