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

---Show help
M.help = function()
  local api = require("nvim-elf-file")
  local opt = require("nvim-elf-file.config").options
  local lines = {}
  for key, cmd in pairs(opt.keymaps) do
    lines[#lines + 1] = '["' .. key .. '"] = "' .. tostring(api.COMMANDS[cmd] .. '"')
  end
  vim.lsp.util.open_floating_preview(lines, "lua", { title = " Keymap: ", border = "rounded", width = 80, height = 10 })
end

---Dumps ELF file symbol table in the current buffer, or restores the ELF file.
M.toggle_elf = function()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].nvim_elf_file == nil then
    vim.b[buf].nvim_elf_file = { is_elf_on = false }
  end

  local api = require("nvim-elf-file")
  local elf = require("nvim-elf-file.elf")
  local opt = require("nvim-elf-file.config").options
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
    function(b)
      vim.bo[b].syntax = "elf"
      for key, value in pairs(opt.keymaps) do
        vim.keymap.set("n", key, "<Plug>(nvim-elf-file-" .. value .. ")", { buffer = b, desc = api.COMMANDS[value] })
      end
    end
  )
end

---Dumps bin as hex in the current buffer, or restores the bin file.
M.toggle_bin = function()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].nvim_elf_file == nil then
    vim.b[buf].nvim_elf_file = { is_bin_on = false }
  end

  -- Make xxd command
  local opt = require("nvim-elf-file.config").options
  local group = opt.xxd.bytes_per_column

  local util = require("nvim-elf-file.util")
  local width = util.get_win_width()

  local bin = require("nvim-elf-file.bin")
  local cols = bin.get_bytes_per_line(group, width)

  local args = { "-g", tostring(group), "-c", tostring(cols), vim.fn.expand("%") }
  if opt.xxd.address_format == "decimal" then
    table.insert(args, 1, "-d")
  end
  if opt.xxd.skip_zeros then
    table.insert(args, 1, "-a")
  end
  if opt.xxd.uppercase then
    table.insert(args, 1, "-u")
  end

  util.toggle(opt.xxd.executable, args, "bin", function(b)
    vim.bo[b].syntax = "xxd"
    local api = require("nvim-elf-file")
    for key, value in pairs(opt.keymaps) do
      vim.keymap.set("n", key, "<Plug>(nvim-elf-file-" .. value .. ")", { buffer = b, desc = api.COMMANDS[value] })
    end
  end)
end

---Dump the section / symbol / function / file under cursor in a new temporary buffer
M.dump = function()
  local elf = require("nvim-elf-file.elf")
  local opt = require("nvim-elf-file.config").options
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
    vim.bo[buf].bufhidden = opt.bufhidden
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
    vim.bo[buf].modified = false
  end)
end

---Show additional information about the item under the cursor
M.hover = function()
  if M.is_elf_file() then
    -- TODO: Show help for <cword>
  else
    local bin = require("nvim-elf-file.bin")
    local opt = require("nvim-elf-file.config").options
    local pos = vim.fn.getpos(".")
    local line, col = pos[2], pos[3]
    local fmt = (opt.xxd.uppercase and "%X" or "%x")
    local address = bin.pos2addr(line, col)
    local lines = {
      tostring(address),
      "0x" .. string.format(fmt, address),
    }
    vim.lsp.util.open_floating_preview(lines, "", { title = " Address: ", border = "rounded" })
  end
end

---Search for text in a bin file
M.search_text = function()
  local strings = {}

  local text = vim.fn.system("strings " .. vim.fn.expand("%"))
  for line in text:gmatch("[^\r\n]+") do
    table.insert(strings, line)
  end
  vim.ui.select(strings, {
    prompt = "Strings:",
  }, function(choice)
    if choice then
      vim.fn.setreg("0", choice)
      vim.notify("Yanked " .. choice .. " to register 0")
    end
  end)
end

---Search for raw bytes in a bin file
M.search_binary = function() end

---Search for raw bytes in a bin file
M.refresh = function() end

---@type table[nvim-elf-file.Command, string]
M.COMMANDS = {
  ["help"] = "Show keybinds",
  ["toggle-elf"] = "Toggle readelf display",
  ["toggle-bin"] = "Toggle xxd binary display",
  ["dump"] = "Dump section/symbol/file under cursor",
  ["hover"] = "Show a hover with additional info",
  ["search-text"] = "Search for text in a binary file",
  ["search-bin"] = "Search for raw bytes in a binary file",
  ["refresh"] = "Reload toggle",
}

---@type table[nvim-elf-file.BufHidden, string]
M.BUF_HIDDEN = {
  [""] = "",
  ["hide"] = "",
  ["unload"] = "",
  ["delete"] = "",
  ["wipe"] = "",
}

---@type nvim-elf-file.LogLevel[]
M.LOG_LEVELS = { "trace", "debug", "info", "warn", "error", "critical" }

return M
