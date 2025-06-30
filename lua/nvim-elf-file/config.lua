local M = {}

---@type nvim-elf-file.Options
M.defaults = {
  readelf = "readelf",
  log_level = "debug",
}

---@type nvim-elf-file.Options
M.options = {}

---
---@param opts nvim-elf-file.Options: plugin options
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

  local util = require("nvim-elf-file.util")
  util.log.level = M.options.log_level
end

return M
