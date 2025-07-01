local M = {}

M.setup = require("nvim-elf-file.config").setup
M.toggle_elf = require("nvim-elf-file.elf").toggle_elf
M.toggle_bin = require("nvim-elf-file.elf").toggle_bin

return M
