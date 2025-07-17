---@meta
---See: https://luals.github.io/wiki/definition-files/
-- luacheck: ignore 631 (line-too-long)

---@alias nvim-elf-file.Command '"toggle"' | '"toggle-elf"' | '"toggle-bin"' | '"dump"' | '"jump"' | '"hover"' | '"search-bin"' | '"search-text"' | '"search-strings"' | '"refresh"' | '"help"'
---@alias nvim-elf-file.BufHidden '""' | '"hide"' | '"unload"' | '"delete"' | '"wipe"'
---@alias nvim-elf-file.LogLevel '"trace"' | '"debug"' | '"info"' | '"warn"' | '"error"' | '"critical"'
---@alias nvim-elf-file.Radix '"hexadecimal"' | '"decimal"'
---@alias nvim-elf-file.SectionKind '"NULL"' | '"PROGBITS"' | '"SYMTAB"' | '"STRTAB"' | '"RELA"' | '"HASH"' | '"DYNAMIC"' | '"NOTE"' | '"NOBITS"' | '"REL"' | '"SHLIB"' | '"DYNSYM"' | '"INIT_ARRAY"' | '"FINI_ARRAY"' | '"PREINIT_ARRAY"' | '"GROUP"' | '"SYMTAB_SHNDX"' | '"GNU_ATTRIBUTES"' | '"GNU_HASH"' | '"GNU_verdef"' | '"GNU_verneed"' | '"GNU_versym"'
---@alias nvim-elf-file.SymbolKind '"NOTYPE"' | '"OBJECT"' | '"FUNC"' | '"SECTION"' | '"FILE"' | '"COMMON"' | '"TLS"'
---@alias nvim-elf-file.SymbolBind '"LOCAL"' | '"GLOBAL"' | '"WEAK"'
---@alias nvim-elf-file.SymbolVis '"DEFAULT"' | '"PROTECTED"' | '"HIDDEN"' | '"INTERNAL"'

---@class nvim-elf-file.XxdUserOptions User configurable xxd options
---@field executable? string Name of or path to xxd executable
---@field bytes_per_column? integer Number of bytes to group in a column (2 nibbles per-byte)
---@field bytes_per_line? integer | '"auto"' Number of bytes to group in a line ("auto" to fill the line)
---@field address_format? nvim-elf-file.Radix How to display the address ("hexadecimal" or "decimal")
---@field skip_zeros? boolean Replace consecutive lines of all '0' with a '*'
---@field uppercase? boolean Use uppercase letters for hexadecimal

---@class nvim-elf-file.XxdOptions xxd options
---@field executable string Name of or path to xxd executable
---@field bytes_per_column integer Number of bytes to group in a column (2 nibbles per-byte)
---@field bytes_per_line integer | '"auto"' Number of bytes to group in a line ("auto" to fill the line)
---@field address_format nvim-elf-file.Radix How to display the address ("hexadecimal" or "decimal")
---@field skip_zeros boolean Replace consecutive lines of all '0' with a '*'
---@field uppercase boolean Use uppercase letters for hexadecimal

---@class nvim-elf-file.UserOptions User configurable options
---@field readelf? string|fun(string?): string Name/path of readelf program or a function taking in a readelf machine and returning a readelf program ($PATH is searched)
---@field objdump? string|fun(string?): string Name/path of objdump program or a function taking in a objdump machine and returning a objdump program ($PATH is searched)
---@field strings? string Name/path of strings program
---@field rg? string Name/path of ripgrep program
---@field xxd? nvim-elf-file.XxdUserOptions xxd settings
---@field keymaps? table[string, nvim-elf-file.Command] plugin buffer-specific key mappings
---@field automatic? table[string, boolean] Disable automatic toggle per-filetype
---@field bufhidden? nvim-elf-file.BufHidden Action to take when exiting a section/symbol dump buffer
---@field log_level? nvim-elf-file.LogLevel Verbosity of `vim.fn.stdpath("state") .. "/nvim-elf-file.log"`
---@field yank_registers? string[] List of registers to copy string to when using ElfFile search text

---@class nvim-elf-file.Options Plugin options, fully resolved
---@field user nvim-elf-file.UserOptions Original user options + defaults
---@field readelf fun(string?): string Function to find readelf based on machine name
---@field objdump fun(string?): string Function to find objdump based on machine name
---@field strings? string Name/path of strings program
---@field rg? string Name/path of ripgrep program
---@field xxd nvim-elf-file.XxdOptions xxd settings
---@field keymaps table[string, nvim-elf-file.Command] plugin buffer-specific key mappings
---@field automatic table[string, boolean] Disable automatic toggle_elf / toggle_bin
---@field bufhidden nvim-elf-file.BufHidden Action to take when exiting a section/symbol dump buffer
---@field log_level nvim-elf-file.LogLevel Verbosity of `vim.fn.stdpath("state") .. "/nvim-elf-file.log"`
---@field yank_registers string[] List of registers to copy string to when using ElfFile search text

---@class nvim-elf-file.Header ELF file header
---@field type string EXEC (executable) or REL (static|shared library/object file)
---@field machine string Architecture of ELF file (e.g. ARM)

---@class nvim-elf-file.Section
---@field id integer Section number
---@field name string Name of the section
---@field kind nvim-elf-file.SectionKind Section type, such as PROGBITS or STRTAB

---@class nvim-elf-file.Symbol
---@field id integer Symbol ID
---@field start integer Start address of symbol
---@field stop integer Stop address of symbol
---@field kind nvim-elf-file.SymbolKind Symbol kind, such as FUNC, OBJECT, FILE, SECTION
---@field bind nvim-elf-file.SymbolBind Symbol bind, such as LOCAL, GLOBAL, or WEAK
---@field visibility nvim-elf-file.SymbolVis Symbol visibility, such as DEFAULT, HIDDEN, or PROTECTED
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
---@field is_bin_on? boolean True if toggle_bin is currently enabled.
---@field is_elf_on? boolean True if toggle_elf is currently enabled.
---@field width? integer Original width of the buffer when first opened with is_<ft>_on.
