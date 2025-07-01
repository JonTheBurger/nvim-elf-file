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

M.disassemble = function()
  local util = require("nvim-elf-file.util")
  local word = vim.fn.expand("<cWORD>")

  if vim.fn.filereadable(word) == 1 then
    -- Edit files like normal
    vim.cmd.edit(word)
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

    -- Trim line to:
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
    local stop = start + tonumber(line:sub(0, end_col - 1))

    -- Trim line to:
    -- "FUNC    GLOBAL DEFAULT   16 main"
    line = util.trim(line:sub(end_col))
    local kind_col = util.find_char(line, " ")
    if kind_col == nil then
      vim.notify("Failed to parse readelf output!", vim.log.levels.ERROR)
      util.log.error("Failed to parse readelf output!")
      return
    end

    -- Parse: "FUNC"
    local kind = line:sub(0, kind_col - 1)

    -- Check if command is valid
    if kind ~= "FUNC" then
      return
    end

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

---Generic in-place buffer toggle
---@param cmd string Command to run to replace buffer contents
---@param ft string FileType used to store buffer state in is_<ft>_on
---@param callback? fun() Called on the buffer when cmd completes
M._toggle = function(cmd, ft, callback)
  local util = require("nvim-elf-file.util")
  local key = "is_" .. ft .. "_on"
  if vim.b.nvim_elf_file == nil then
    ---@type nvim-elf-file.BufferOpts
    vim.b.nvim_elf_file = {}
  end

  if vim.b.nvim_elf_file[key] == false then
    util.log.trace("toggle " .. key .. " was false")

    -- Store previous state, temporarily make buffer writable
    local buf_state = util.get_buf_state()
    vim.bo.modifiable = true
    vim.bo.readonly = false

    util.log.info(cmd)
    vim.cmd("%!" .. cmd)

    -- Set modified to false (even though we just replaced buffer contents)
    vim.bo.modified = false
    vim.bo.modifiable = false
    vim.bo.readonly = true

    vim.b.nvim_elf_file = {
      buf_state = buf_state,
      [key] = true,
    }

    if callback ~= nil then
      callback()
    end
  elseif vim.b.nvim_elf_file[key] == true then
    util.log.trace("toggle " .. key .. " was true")

    local buf_state = vim.b.nvim_elf_file.buf_state
    vim.b.nvim_elf_file = { [key] = nil }

    vim.cmd.edit("%")

    util.set_buf_state(buf_state or {})
    vim.b.nvim_elf_file = { [key] = false }
  else
    -- Commands like vim.cmd.edit(...) re-invoke this function with vim.b cleared.
    -- This causes vim.b.nvim_elf_file[key] to be `nil`.
    -- We use the nil case as a no-op to prevent infinite recursion
    util.log.trace("toggle " .. key .. " was nil")
  end
end

M.toggle_elf = function()
  local cmd = "readelf -W -C -s " .. vim.fn.expand("%")
  M._toggle(cmd, "elf", function()
    vim.keymap.set("n", "<cr>", M.disassemble, { buffer = true, desc = "Disassemble" })
  end)
end

M.toggle_bin = function()
  M._toggle("xxd", "bin")
end

return M
