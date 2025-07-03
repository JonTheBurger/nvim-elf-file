local M = {}

---All ELF files start with this sequence of bytes
M.MAGIC = "\x7fELF"

---Checks if a file is an ELF file by searching for magic bytes at file start.
---@param file string|integer? Path or buffer number to check (default: 0, AKA current buffer)
---@return boolean true if the given file is an elf file, false otherwise.
M.is_elf_file = function(file)
  local is_elf = false

  if file == nil then
    file = 0
  end

  -- First 4 chars should be magic ELF sequence
  if type(file) == "number" then
    is_elf = vim.api.nvim_buf_get_text(file, 0, 0, 0, 4, {})[1] == M.MAGIC
  elseif type(file) == "string" then
    local f, err = io.open(file, "rb")
    if f then
      is_elf = f:read(4) == M.MAGIC
      f:close()
    else
      local logger = require("nvim-elf-file.util").log
      logger.error(err)
    end
  end

  return is_elf
end

---Checks if a readelf line refers to a section
---Looks for a number in square brackets at line start, e.g. "  [ 12]"
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
    -- nvim will have plain Lua 5.1 at worst, which does not have goto & ::continue::
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

  util.log.debug(vim.inspect(header))
  return header
end

---Parses readelf section line output into structured data, for example:
---"  [16] .text             PROGBITS        00000000000010e0 0010e0 000177 00  AX  0   0 16"
---@param line string Readelf section line to parse
---@return nvim-elf-file.Section? or nil on error
M.parse_section = function(line)
  local util = require("nvim-elf-file.util")
  local section = {}
  local _

  -- "  [16] .text             PROGBITS        00000000000010e0 0010e0 000177 00  AX  0   0 16"
  local ok, col, field = line:find("^%s*%[%s*(%d+)%]%s*")
  if ok == nil then
    util.log.info("Couldn't find section id")
    return nil
  end
  section.id = tonumber(field)

  line = line:sub(col + 1)
  -- ".text             PROGBITS        00000000000010e0 0010e0 000177 00  AX  0   0 16"
  ok, col, field = line:find("^(%S+)%s*")
  if ok == nil then
    util.log.info("Couldn't find section name")
    return nil
  end
  section.name = field

  line = line:sub(col + 1)
  -- "PROGBITS        00000000000010e0 0010e0 000177 00  AX  0   0 16"
  ok, _, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find section kind")
    return nil
  end
  section.kind = field

  util.log.debug(vim.inspect(section))
  return section
end

---Parses readelf symbol line output into structured data, for example:
-- "    29: 00000000000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
---@param line string Readelf symbol line to parse
---@return nvim-elf-file.Symbol? or nil on error
M.parse_symbol = function(line)
  local util = require("nvim-elf-file.util")
  local symbol = {}
  local _

  -- "    29: 000000001000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
  local ok, col, field = line:find("^%s*(%d+):%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol id")
    return nil
  end
  symbol.id = field

  line = line:sub(col + 1)
  -- "00000000000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
  ok, col, field = line:find("^(%x+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol start address")
    return nil
  end
  symbol.start = tonumber(field, 16)

  line = line:sub(col + 1)
  -- "72 FUNC    GLOBAL DEFAULT   16 main"
  ok, col, field = line:find("(%d+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol size")
    return nil
  end
  symbol.stop = symbol.start + tonumber(field)

  line = line:sub(col + 1)
  -- "FUNC    GLOBAL DEFAULT   16 main"
  ok, col, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol kind")
    return nil
  end
  symbol.kind = field

  line = line:sub(col + 1)
  -- "GLOBAL DEFAULT   16 main"
  ok, col, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol bind")
    return nil
  end
  symbol.bind = field

  line = line:sub(col + 1)
  -- "DEFAULT   16 main"
  ok, col, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol visibility")
    return nil
  end
  symbol.visibility = field

  line = line:sub(col + 1)
  -- "16 main"
  ok, col, field = line:find("^(%w+)%s*")
  if ok == nil then
    util.log.info("Couldn't find symbol section index")
    return nil
  end
  symbol.section_idx = field

  line = line:sub(col + 1)
  -- "main"
  ok, _, field = line:find("^(.*)")
  if ok == nil then
    util.log.info("Couldn't find symbol section index")
    return nil
  end
  symbol.name = field

  util.log.debug(vim.inspect(symbol))
  return symbol
end

---Checks ELF headers to select readelf
---@param file? string ELF file to read header
---@return string Architecture-specific readelf command
M.readelf = function(file)
  if not file then
    file = vim.fn.expand("%")
  end
  local opt = require("nvim-elf-file.config").options
  local exe = opt.readelf("")
  local output = vim.fn.system({
    exe,
    "--wide",
    "--file-header",
    file,
  })

  local header = M.parse_header(output)
  if header ~= nil then
    exe = opt.readelf(header.machine)
  end
  return exe
end

---Checks ELF headers to select objdump
---@param file? string ELF file to read header
---@return string Architecture-specific objdump command
M.objdump = function(file)
  if not file then
    file = vim.fn.expand("%")
  end
  local opt = require("nvim-elf-file.config").options
  local readelf = opt.readelf("")
  local output = vim.fn.system({
    readelf,
    "--wide",
    "--file-header",
    file,
  })

  local header = M.parse_header(output)
  if header ~= nil then
    return opt.objdump(header.machine)
  end
  return opt.objdump("")
end

return M
