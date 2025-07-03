local M = {}

---Set up the plugin with custom settings
---@param opts nvim-elf-file.UserOptions Plugin options
M.setup = function(opts)
  require("nvim-elf-file.config").setup(opts)
end

---Checks if a file is an ELF file by searching for magic bytes at file start.
---@param file string|integer? Path or buffer number to check (default: 0, AKA current buffer)
---@return boolean true if the given file is an elf file, false otherwise.
M.is_elf_file = function(file)
  return require("nvim-elf-file.elf").is_elf_file(file)
end

---Dumps ELF file symbol table in the current buffer, or restores the ELF file.
M.toggle_elf = function()
  local elf = require("nvim-elf-file.elf")
  local util = require("nvim-elf-file.util")
  util.toggle(
    elf.readelf(),
    {
      "--wide",
      "--demangle",
      "--section-headers",
      "--syms",
      vim.fn.expand("%"),
    },
    "elf",
    function(buf)
      vim.bo[buf].syntax = "elf"
      vim.keymap.set(
        "n",
        "<cr>",
        "<Plug>(nvim-elf-file-dump)",
        { buffer = buf, desc = "Dump section/symbol/file under cursor" }
      )
    end
  )
end

---Dumps bin as hex in the current buffer, or restores the bin file.
M.toggle_bin = function()
  if vim.b.nvim_elf_file == nil then
    vim.b.nvim_elf_file = { is_bin_on = false }
  end

  local util = require("nvim-elf-file.util")
  util.toggle("xxd", { vim.fn.expand("%") }, "bin", function(buf)
    vim.bo[buf].syntax = "xxd"
  end)
end

---Dump the section / symbol / function / file under cursor in a new temporary buffer
M.dump = function()
  local elf = require("nvim-elf-file.elf")
  local util = require("nvim-elf-file.util")

  local line = vim.fn.getline(".")
  local cmd
  local args
  local bname

  if elf.is_section_line(line) then
    local section = elf.parse_section(line)

    if section == nil then
      vim.notify("Failed to parse readelf output!", vim.log.levels.ERROR)
      util.log.error("Failed to parse readelf output!")
      return
    end

    bname = section.name
    -- Build command
    cmd = elf.readelf()
    args = { "--wide", "--string-dump", section.name }
    if section.kind ~= "STRTAB" and section.name ~= ".debug_line_str" and section.name ~= ".debug_str" then
      args[#args + 1] = "--hex-dump"
      args[#args + 1] = section.name
    end
    args[#args + 1] = vim.fn.expand("%")
  else
    local symbol = elf.parse_symbol(line)

    -- Check validity
    if symbol == nil then
      vim.notify("Failed to parse readelf output!", vim.log.levels.ERROR)
      util.log.error("Failed to parse readelf output!")
      return
    end

    if symbol.kind == "FILE" and vim.fn.filereadable(symbol.name) == 1 then
      vim.cmd.edit(symbol.name)
      return
    end

    if symbol.stop <= symbol.start then
      vim.notify("Cannot disassemble empty symbol " .. symbol.name)
      util.log.info("Cannot disassemble empty symbol " .. symbol.name)
      return
    end

    bname = "." .. symbol.name .. ".asm"
    -- Build command
    cmd = elf.objdump()
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
  vim.bo[buf].swapfile = false
  util.buf_from_cmd_async(buf, cmd, args, function()
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
    vim.bo[buf].modified = false
  end)
end

---Show additional information about the item under the cursor
-- M.hover = function()
-- end

---Search for raw bytes in a bin file
-- M.search = function()
-- end

return M
