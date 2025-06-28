---@class Config
local M = {}

---@class Options
M.defaults = {}

---@class Options
M.options = {}

---
---@param opts Options: plugin options
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
