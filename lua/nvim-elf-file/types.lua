---@meta
---See: https://luals.github.io/wiki/definition-files/
-- luacheck: ignore 631 (line-too-long)

---@alias nvim-elf-file.Command '"toggle-elf"' | '"toggle-bin"' | '"dump"' -- | '"hover"' | '"search"'
---@alias nvim-elf-file.BufHidden '""' | '"hide"' | '"unload"' | '"delete"' | '"wipe"'
---@alias nvim-elf-file.LogLevel '"trace"' | '"debug"' | '"info"' | '"warn"' | '"error"' | '"critical"'

---@class nvim-elf-file.UserOptions User configurable options
---@field readelf? string|fun(string): string Name/path of readelf program or a function taking in a readelf machine and returning a readelf program ($PATH is searched)
---@field objdump? string|fun(string): string Name/path of objdump program or a function taking in a objdump machine and returning a objdump program ($PATH is searched)
---@field xxd? string Name/path of xxd program ($PATH is searched)
---@field keymaps? table[string, nvim-elf-file.Command] plugin buffer-specific key mappings
---@field automatic? table[string, boolean] Disable automatic toggle per-filetype
---@field bufhidden? nvim-elf-file.BufHidden Action to take when exiting a section/symbol dump buffer
---@field log_level? nvim-elf-file.LogLevel Verbosity of `vim.fn.stdpath("state") .. "/nvim-elf-file.log"`

---@class nvim-elf-file.Options Plugin options, fully resolved
---@field user nvim-elf-file.UserOptions Original user options + defaults
---@field readelf fun(string): string Function to find readelf based on machine name
---@field objdump fun(string): string Function to find objdump based on machine name
---@field xxd string xxd program
---@field keymaps table[string, nvim-elf-file.Command] plugin buffer-specific key mappings
---@field automatic table[string, boolean] Disable automatic toggle_elf / toggle_bin
---@field bufhidden nvim-elf-file.BufHidden Action to take when exiting a section/symbol dump buffer
---@field log_level nvim-elf-file.LogLevel Verbosity of `vim.fn.stdpath("state") .. "/nvim-elf-file.log"`

---@class nvim-elf-file.Header ELF file header
---@field type string EXEC (executable) or REL (static|shared library/object file)
---@field machine string Architecture of ELF file (e.g. ARM)

---@class nvim-elf-file.Section
---@field id integer Section number
---@field name string Name of the section
---@field kind string Section type, such as PROGBITS or STRTAB

---@class nvim-elf-file.Symbol
---@field id integer Symbol ID
---@field start integer Start address of symbol
---@field stop integer Stop address of symbol
---@field kind string Symbol kind, such as FUNC, OBJECT, FILE, SECTION
---@field bind string Symbol bind, such as LOCAL, GLOBAL, or WEAK
---@field visibility string Symbol visibility, such as DEFAULT, HIDDEN, or PROTECTED
---@field section_idx integer|string Which section id the symbol belongs to, or UND/ABS/COMMON
---@field name string Name of symbol

---@class nvim-elf-file.BufferState Previous state of a buffer
---@field binary boolean vim.bo.binary
---@field modifiable boolean vim.bo.modifiable
---@field modified boolean vim.bo.modified
---@field readonly boolean vim.bo.readonly
---@field filetype string vim.bo.filetype

---@class nvim-elf-file.BufferOpts Records if a buffer has been toggle_bin'd etc.
---@field buf_state? nvim-elf-file.BufferState Previous state of the buffer.
