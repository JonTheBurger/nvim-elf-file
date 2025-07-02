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
    local kind = line:match("%s*Type:%s*(%S.*)")
    if kind then
      header.type = kind
      goto continue
    end

    local machine = line:match("%s*Machine:%s*(%S.*)")
    if machine then
      header.machine = machine
      goto continue
    end

    ::continue::
  end

  if not header.type or not header.machine then
    util.log.trace("Couldn't parse header fields")
    return nil
  end
  return header
end

---Parses readelf section line output into structured data, for example:
---"  [16] .text             PROGBITS        00000000000010e0 0010e0 000177 00  AX  0   0 16"
---@param line string Readelf section line to parse
---@return nvim-elf-file.Section? or nil on error
M.parse_section = function(line)
  local util = require("nvim-elf-file.util")

  -- Find: "[16]"
  local start_col = util.find_char(line, "[")
  local end_col = util.find_char(line, "]")
  util.log.trace(tostring(start_col) .. " " .. tostring(end_col))
  if start_col == nil or end_col == nil then
    util.log.trace("Couldn't find section id")
    return nil
  end
  local id = tonumber(line:sub(start_col + 1, end_col - 1))

  -- Find: ".text"
  line = line:sub(end_col + 1)
  start_col = util.skip_char(line, " ")
  if start_col == nil or end_col == nil then
    util.log.trace("Couldn't find section name start")
    return nil
  end
  end_col = util.find_char(line, " ", start_col)
  if start_col == nil or end_col == nil then
    util.log.trace("Couldn't find section name end")
    return nil
  end
  local name = line:sub(start_col, end_col - 1)

  -- Find: "PROGBITS"
  line = line:sub(end_col + 1)
  start_col = util.skip_char(line, " ")
  if start_col == nil or end_col == nil then
    util.log.trace("Couldn't find section name start")
    return nil
  end
  end_col = util.find_char(line, " ", start_col)
  if start_col == nil or end_col == nil then
    util.log.trace("Couldn't find section name end")
    return nil
  end
  local kind = line:sub(start_col, end_col - 1)

  return { id = id, name = name, kind = kind }
end

---Parses readelf symbol line output into structured data, for example:
-- "    29: 00000000000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
---@param line string Readelf symbol line to parse
---@return nvim-elf-file.Symbol? or nil on error
M.parse_symbol = function(line)
  local util = require("nvim-elf-file.util")

  -- Find:
  -- "00000000000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
  local start_col = util.find_char(line, ":")
  if start_col == nil then
    util.log.trace("Couldn't find symbol id")
    return nil
  end
  start_col = start_col + 2

  -- Find:
  -- "00000000000011c9 "
  local end_col = util.find_char(line, " ", start_col)
  if end_col == nil then
    util.log.trace("Couldn't find end of address")
    return nil
  end

  -- Parse:
  -- "00000000000011c9"
  local start = tonumber(line:sub(start_col, end_col), 16)

  -- Trim line to:
  -- "72 FUNC    GLOBAL DEFAULT   16 main"
  line = util.trim(line:sub(end_col))
  end_col = util.find_char(line, " ")
  if end_col == nil then
    util.log.trace("Couldn't find end of size")
    return nil
  end

  -- Parse:
  -- "72"
  local stop = start + tonumber(line:sub(0, end_col - 1))

  -- Trim line to:
  -- "FUNC    GLOBAL DEFAULT   16 main"
  line = util.trim(line:sub(end_col))
  local kind_col = util.find_char(line, " ")
  if kind_col == nil then
    util.log.trace("Couldn't find end of symbol kind")
    return nil
  end

  -- Parse: "FUNC"
  local kind = line:sub(0, kind_col - 1)

  return { start = start, stop = stop, kind = kind }
end

---Dump the section / symbol / function / file under cursor in a new temporary buffer
M.dump = function()
  local util = require("nvim-elf-file.util")
  local word = vim.fn.expand("<cWORD>")

  if vim.fn.filereadable(word) == 1 then
    -- Edit files like normal
    vim.cmd.edit(word)
  else
    local line = vim.fn.getline(".")
    local cmd
    local args
    local bname

    if M.is_section_line(line) then
      local section = M.parse_section(line)

      if section == nil then
        vim.notify("Failed to parse readelf output!", vim.log.levels.ERROR)
        util.log.error("Failed to parse readelf output!")
        return
      end

      bname = section.name
      -- Build command
      cmd = M.readelf()
      args = { "--wide", "-p", section.name }
      if section.kind ~= "STRTAB" and section.name ~= ".debug_line_str" and section.name ~= ".debug_str" then
        args[#args + 1] = "-x"
        args[#args + 1] = section.name
      end
      args[#args + 1] = vim.fn.expand("%")
    else
      local symbol = M.parse_symbol(line)

      -- Check validity
      if symbol == nil then
        vim.notify("Failed to parse readelf output!", vim.log.levels.ERROR)
        util.log.error("Failed to parse readelf output!")
        return
      end

      ---@diagnostic disable-next-line: need-check-nil
      if symbol.stop <= symbol.start then
        vim.notify("Cannot disassemble empty symbol " .. word)
        util.log.info("Cannot disassemble empty symbol " .. word)
        return
      end

      bname = "." .. word .. ".asm"
      -- Build command
      cmd = M.objdump()
      args = { "--wide", "--demangle", "--start-address", symbol.start, "--stop-address", symbol.stop }
      if symbol.kind == "FUNC" then
        args[#args + 1] = "--source"
      else
        args[#args + 1] = "--full-contents"
      end
      args[#args + 1] = vim.fn.expand("%")
    end

    -- Open Temporary Buffer with Result
    util.log.info(cmd .. " " .. table.concat(args, " "))
    vim.cmd.edit(bname)
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
    util.buf_from_cmd_async(buf, cmd, args, function()
      vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
      vim.api.nvim_set_option_value("readonly", true, { buf = buf })
      vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
      vim.api.nvim_set_option_value("modified", false, { buf = buf })
    end)
  end
end

---Checks ELF headers to select readelf
---@param file? string ELF file to read header
---@return string Architecture-specific readelf command
M.readelf = function(file)
  if not file then
    file = vim.fn.expand("%")
  end
  local output = vim.fn.system({
    "readelf",
    "--wide",
    "--file-header",
    file,
  })

  local header = M.parse_header(output)
  if header and header.machine == "ARM" then
    return "arm-none-eabi-readelf"
  end

  return "readelf"
end

---Checks ELF headers to select objdump
---@param file? string ELF file to read header
---@return string Architecture-specific objdump command
M.objdump = function(file)
  if not file then
    file = vim.fn.expand("%")
  end
  local output = vim.fn.system({
    "readelf",
    "--wide",
    "--file-header",
    file,
  })

  local header = M.parse_header(output)
  if header and header.machine == "ARM" then
    return "arm-none-eabi-objdump"
  end

  return "objdump"
end

---Dumps ELF file symbol table in the current buffer, or restores the ELF file.
M.toggle_elf = function()
  local util = require("nvim-elf-file.util")
  util.toggle(
    M.readelf(),
    {
      "--wide",
      "--demangle",
      "--section-headers",
      "--syms",
      vim.fn.expand("%"),
    },
    "elf",
    function(buf)
      vim.api.nvim_set_option_value("syntax", "elf", { buf = buf })
      vim.keymap.set("n", "<cr>", M.dump, { buffer = true, desc = "Dump section/symbol/file under cursor" })
    end
  )
end

---Dumps bin as hex in the current buffer, or restores the bin file.
M.toggle_bin = function()
  local util = require("nvim-elf-file.util")
  util.toggle("xxd", { vim.fn.expand("%") }, "bin", function(buf)
    vim.api.nvim_set_option_value("syntax", "xxd", { buf = buf })
  end)
end

return M
