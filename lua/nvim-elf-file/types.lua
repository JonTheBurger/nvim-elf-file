---@meta
---See: https://luals.github.io/wiki/definition-files/

---@class nvim-elf-file.Options
---@field readelf string|fun(): string
---@field log_level string

---@class nvim-elf-file.Section
---@field id integer Section number
---@field name string Name of the section
---@field kind string Section type, such as PROGBITS or STRTAB

---@class nvim-elf-file.Symbol
---@field start integer Start address of symbol
---@field stop integer Stop address of symbol
---@field kind string Symbol kind, such as FUNC

---@class nvim-elf-file.BufferState
---Previous state of a buffer
---@field binary boolean
---@field modifiable boolean
---@field modified boolean
---@field readonly boolean
---@field filetype string

---@class nvim-elf-file.BufferOpts
---Records if a buffer has been readelf'd etc. is_<x>_on variables are used to
---determine if it's in a "virtual" file mode like readelf mode. Note that many
---vim functions clear vim.b, such as vim.fn.edit. To account for cases where
---is_<x>_on is set to nil, a nil value is treated as a no-op by the toggle
---functions.
---@field buf_state? nvim-elf-file.BufferState Previous state of the buffer.
