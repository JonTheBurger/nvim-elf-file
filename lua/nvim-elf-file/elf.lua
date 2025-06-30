local M = {}

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

M.toggle = function()
  local util = require("nvim-elf-file.util")
  local buf_state = util.get_buf_state()

  if not vim.b.nvim_elf_file then
    vim.b.nvim_elf_file = {
      prev_state = buf_state
    }
    vim.bo.binary = true

    vim.cmd("silent edit") --  .. vim.fn.tempname()
    vim.cmd("%!readelf -W -C -s " .. vim.fn.expand("%"))
    vim.keymap.set("n", "<cr>", M.disassemble, { buffer = true, desc = "Disassemble" })
  else
    util.set_buf_state(vim.b.nvim_elf_file.prev_state)
    vim.b.nvim_elf_file = nil
  end
end

M.disassemble = function()
  local util = require("nvim-elf-file.util")
  local word = vim.fn.expand("<cWORD>")

  if vim.fn.filereadable(word) == 1 then
    -- Edit files like normal
    vim.cmd("silent edit " .. word)
  else
    -- Else read the line, for example:
    -- "    29: 00000000000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
    local line = vim.fn.getline(".")
    util.log.debug("Parsing " .. line)

    -- Find:
    -- "00000000000011c9    72 FUNC    GLOBAL DEFAULT   16 main"
    local start_col = util.find_char(line, ":")
    if start_col == nil then
      vim.notify("Failed to parse readelf output!", vim.log.levels.ERROR)
      util.log.error("Failed to parse readelf output!")
      return
    end
    start_col = start_col + 2

    -- Find:
    -- "00000000000011c9 "
    local end_col = util.find_char(line, " ", start_col)
    if end_col == nil then
      vim.notify("Failed to parse readelf output!", vim.log.levels.ERROR)
      util.log.error("Failed to parse readelf output!")
      return
    end

    -- Parse:
    -- "00000000000011c9"
    local start = tonumber(line:sub(start_col, end_col), 16)

    -- Find:
    -- "72 FUNC    GLOBAL DEFAULT   16 main"
    line = util.trim(line:sub(end_col))
    end_col = util.find_char(line, " ")
    if end_col == nil then
      vim.notify("Failed to parse readelf output!", vim.log.levels.ERROR)
      util.log.error("Failed to parse readelf output!")
      return
    end

    -- Parse:
    -- "72"
    local stop = start + tonumber(line:sub(0, end_col))

    -- Check if command is valid
    if stop == start then
      vim.notify("Cannot disassemble empty function " .. word)
      util.log.info("Cannot disassemble empty function " .. word)
      return
    end
    local cmd = "objdump -C -S --start-address " .. start .. " --stop-address " .. stop .. " " .. vim.fn.expand("%")
    util.log.info(cmd)

    -- Open Disassembly
    vim.cmd.edit("." .. word .. ".asm")
    vim.cmd("%!" .. cmd)
    vim.bo.bufhidden = "wipe"
    vim.bo.modifiable = false
    vim.bo.modified = false
    vim.bo.swapfile = false
  end
end

return M
