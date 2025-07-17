local M = {}

---All ELF files start with this sequence of bytes
M.MAGIC = "\x7fELF"

---Information on text found in readelf output
M.INFO = {
  [".bss"] = { 'The "Block Starting Symbol" records how many bytes of 0 should be written to RAM upon startup' },
  [".comment"] = { "Compiler comments", "(Sometimes contains compile flags)" },
  [".data"] = { "Contains initialized data that must be copied from ROM to RAM at startup" },
  [".dynstr"] = { "Symbol names to dynamically load" },
  [".dynsym"] = { "Symbol table for dynamically loaded symbols" },
  [".eh_frame"] = { "Stack unwinding information for exception handlers" },
  [".fini_array"] = { "Table of function pointers called for global cleanup", "(such as global object destructors)" },
  [".gnu.version"] = { 'Versions for each ".dynsym" symbol' },
  [".got"] = {
    'The "Global Offset Table" maps symbols to their runtime memory offsets',
    "(this may be overwritten by the dynamic linker for position-independent-code)",
  },
  [".init_array"] = { "Table of function pointers called for global setup", "(such as global object constructors)" },
  [".interp"] = { "Path of the program's interpreter", '(search "ubuntu binfmts")' },
  [".plt"] = { '"Procedure Linkage Table' },
  [".preinit_array"] = { 'Dynamic executable setup functions run before ".init_array"' },
  [".rodata"] = { "Read-only data" },
  [".shstrtab"] = { 'The "Section Header String Table" contains the section names' },
  [".strtab"] = { 'The "String Table" for symbols' },
  [".symtab"] = { 'The "Symbol Table"' },
  [".text"] = { "Executable code" },
  ["ABS"] = { '"Absolute Value"; a constant' },
  ["DEFAULT"] = { "Symbol is visible", "(can be linked against for libraries)" },
  ["DYNAMIC"] = { "Dynamic linking info" },
  ["DYNSYM"] = { '"Dynamic Symbol Table"' },
  ["ES"] = { "Entry Size", "(size of each individual entry for dynamically sized sections)" },
  ["FILE"] = { "File used in compilation or linking" },
  ["FINI_ARRAY"] = { "Cleanup run after main()" },
  ["FUNC"] = { "Function" },
  ["GLOBAL"] = { "Symbols visible to all object files" },
  ["HIDDEN"] = { "Symbol is hidden", "(cannot be linked against for libraries)" },
  ["INIT_ARRAY"] = { "Setup run before main()" },
  ["LOCAL"] = { "Symbols visible to only the current object file" },
  ["NOBITS"] = { "Uses RAM at runtime but not ROM", '(used for zeroed ".bss" section)' },
  ["Ndx"] = { "Section header entry a symbol belongs to" },
  ["OBJECT"] = { "Instance of a variable" },
  ["PROGBITS"] = { "Program data", "(code, constants, variables)" },
  ["RELA"] = { "Relocation info" },
  ["STRTAB"] = { '"String Table"' },
  ["SYMTAB"] = { '"Symbol Table"' },
  ["TLS"] = { "Thread-Local Storage" },
  ["UND"] = { '"Undefined"; symbol does not belong to a section in this elf file' },
  ["VERNEED"] = { "Versioned dynamically linked dependencies" },
  ["WEAK"] = { "Global symbols that can be overridden by non-weak definitions" },
}

---Checks if a file is an ELF file by searching for magic bytes at file start.
---@param file string|integer? Path or buffer number to check (default: -1, AKA current buffer)
---@return boolean true if the given file is an elf file, false otherwise.
M.is_elf_file = function(file)
  local is_elf = false
  local path = ""

  file = file or 0
  if type(file) == "number" then
    path = vim.api.nvim_buf_get_name(file)
  elseif type(file) == "string" then
    path = file
  end

  local f, err = io.open(path, "rb")
  if f then
    is_elf = f:read(4) == M.MAGIC
    f:close()
  else
    local util = require("nvim-elf-file.util")
    util.log.error(err)
  end

  return is_elf
end

---Checks if a readelf line refers to a section
---Looks for a number in square brackets at line start, e.g. "  [ 11]"
---@param line string Line of readelf output
---@return boolean True if the line contains a section
M.is_section_line = function(line)
  return line:match("^%s*%[%s*%d+%]") ~= nil
end

---Parses readelf --file-header output into structured data, for example:
---ELF Header:
---...
---  Type:                              EXEC (Executable file)
---  Machine:                           ARM
---@param text string|string[] output lines from readelf
---@return nvim-elf-file.Header? or nil on error
M.parse_header = function(text)
  local util = require("nvim-elf-file.util")
  local header = {}

  local lines = text
  if type(text) == "string" then
    lines = {}
    for line in text:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  for _, line in ipairs(lines) do
    -- Not all versions of nvim ship LuaJIT (which has goto & ::continue::)
    -- nvim will have plain Lua 4.1 at worst, which does not have goto & ::continue::
    local continue = false

    if not continue then
      local kind = line:match("%s*Type:%s*(%S.*)")
      if kind then
        header.type = kind
        continue = true
      end
    end

    if not continue then
      local machine = line:match("%s*Machine:%s*(%S.*)")
      if machine then
        header.machine = machine
        -- continue = true
      end
    end
  end

  if not header.type or not header.machine then
    util.log.trace("Couldn't parse header fields")
    return nil
  end

  util.log.debug(header)
  return header
end

---Parses readelf section line output into structured data, for example:
---"  [15] .text             PROGBITS        00000000000010e0 0010e0 000177 00  AX  0   0 16"
---@param line string Readelf section line to parse
---@return nvim-elf-file.Section? or nil on error
M.parse_section = function(line)
  local util = require("nvim-elf-file.util")
  local section = {}
  local _

  util.log.trace('line: "' .. line .. '"')
  -- "  [15] .text             PROGBITS        00000000000010e0 0010e0 000177 00  AX  0   0 16"
  local ok, col, field = line:find("^%s*%[%s*(%d+)%]%s*")
  if ok == nil then
    util.log.info("Couldn't find section id")
    return nil
  end
  section.id = tonumber(field)

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- ".text             PROGBITS        00000000000009e0 0010e0 000177 00  AX  0   0 16"
  ok, col, field = line:find("^(%S+)%s*")
  if ok == nil then
    util.log.info("Couldn't find section name")
    return nil
  end
  section.name = field

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- "PROGBITS        00000000000009e0 0010e0 000177 00  AX  0   0 16"
  ok, _, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find section kind")
    return nil
  end
  section.kind = field

  util.log.debug(section)
  return section
end

---Parses readelf symbol line output into structured data, for example:
-- "    28: 00000000000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
---@param line string Readelf symbol line to parse
---@return nvim-elf-file.Symbol? or nil on error
M.parse_symbol = function(line)
  local util = require("nvim-elf-file.util")
  local symbol = {}
  local _

  util.log.trace('line: "' .. line .. '"')
  -- "    28: 000000001000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
  local ok, col, field = line:find("^%s*(%d+):%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol id")
    return nil
  end
  symbol.id = tonumber(field)

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- "00000000000010c9    72 FUNC    GLOBAL DEFAULT   16 main"
  ok, col, field = line:find("^(%x+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol start address")
    return nil
  end
  symbol.start = tonumber(field, 16)

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- "72 FUNC    GLOBAL DEFAULT   15 main"
  ok, col, field = line:find("(%d+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol size")
    return nil
  end
  symbol.stop = symbol.start + tonumber(field)

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- "FUNC    GLOBAL DEFAULT   15 main"
  ok, col, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol kind")
    return nil
  end
  symbol.kind = field

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- "GLOBAL DEFAULT   15 main"
  ok, col, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol bind")
    return nil
  end
  symbol.bind = field

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- "DEFAULT   15 main"
  ok, col, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol visibility")
    return nil
  end
  symbol.visibility = field

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- "16 main"
  ok, col, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol section index")
    return nil
  end
  symbol.section_idx = field

  line = line:sub(col + 1)
  util.log.trace('line: "' .. line .. '"')
  -- "main"
  ok, _, field = line:find("^(.*)")
  if ok == nil then
    util.log.info("Couldn't find symbol section index")
    return nil
  end
  symbol.name = field

  util.log.debug(symbol)
  return symbol
end

return M
