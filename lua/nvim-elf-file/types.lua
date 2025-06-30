---@meta
---See: https://luals.github.io/wiki/definition-files/

---@class nvim-elf-file.Options
---@field readelf string|fun(): string
---@field log_level string

---@class nvim-elf-file.BufferState
---Previous state of a buffer
---@field binary boolean
---@field modifiable boolean
---@field modified boolean
---@field readonly boolean
---@field file? string
