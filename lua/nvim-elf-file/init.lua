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
  local util = require("nvim-elf-file.util")
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].nvim_elf_file == nil then
    vim.b[buf].nvim_elf_file = { is_bin_on = false, width = util.get_win_width() }
  end
  vim.b[buf].nvim_elf_file.width = util.get_win_width()

  -- Make xxd command
  local opt = require("nvim-elf-file.config").options
  local group = opt.xxd.bytes_per_column

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

---Toggle based on file type
M.toggle = function()
  if M.is_elf_file() then
    M.toggle_elf()
  else
    M.toggle_bin()
  end
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
    -- "--start-address", symbol.start, "--stop-address", symbol.stop
    args = { "--wide", "--demangle", "--disassemble=" .. symbol.name }
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

---Jump to an address in a bin file
M.jump = function()
  local bin = require("nvim-elf-file.bin")

  vim.ui.input({ prompt = "Jump to Address: (hex or decimal)", default = "0x" }, function(text)
    if not text then
      return
    end

    local address = tonumber(text)
    if not address then
      vim.notify("Invalid address: " .. text, vim.log.levels.ERROR)
    end
    vim.api.nvim_win_set_cursor(0, bin.addr2pos(address))
  end)
end

---Show additional information about the item under the cursor
M.hover = function()
  local util = require("nvim-elf-file.util")
  if M.is_elf_file() then
    local elf = require("nvim-elf-file.elf")
    local word = vim.fn.expand("<cWORD>")
    local info = elf.INFO[word]
    util.log.trace("hover info for: " .. word)

    if info == nil then
      if word:match("^%x+$") then
        info = { string.format("%d", tonumber(word, 16)) }
      else
        info = { "No info found" }
      end
    end

    vim.lsp.util.open_floating_preview(info, "", { title = " Info: ", border = "rounded" })
  else
    local bin = require("nvim-elf-file.bin")
    local opt = require("nvim-elf-file.config").options
    local pos = vim.fn.getpos(".")
    local buf, line, col = pos[1], pos[2], pos[3]
    local fmt = (opt.xxd.uppercase and "%X" or "%x")
    local width = vim.b[buf].nvim_elf_file.width
    local address = bin.pos2addr(line, col, width)
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
M.search_binary = function()
  vim.ui.input({ prompt = "Search Hex: (0-9, a-f, A-F)", default = "" }, function(text)
    local bin = require("nvim-elf-file.bin")
    local util = require("nvim-elf-file.util")
    -- Clean up user input
    text = text or ""
    text = text:gsub("^0[xX]", "")
    text = text:gsub("[^A-Fa-f0-9]", "")
    if #text % 2 ~= 0 then
      text = "0" .. text
    end
    if text == "" then
      return
    end
    util.log.debug("Searching for " .. text)

    local pattern = ""
    for i = 1, #text, 2 do
      pattern = pattern .. "\\x" .. text:sub(i, i) .. text:sub(i + 1, i + 1)
    end

    local cmd = {
      "rg",
      "--text",
      "--only-matching",
      "--byte-offset",
      "(?-u:" .. pattern .. ")",
      vim.fn.expand("%"),
    }

    vim.system(cmd, {}, function(out)
      if out.code ~= 0 then
        return
      end

      local choices = {}
      for addr in out.stdout:gmatch("%d+") do
        choices[#choices + 1] = addr
      end
      if #choices > 0 then
        vim.schedule(function()
          vim.ui.select(choices, {
            prompt = "Which occurrence?",
            format_item = function(item)
              return item .. " (0x" .. string.format("%x", tonumber(item)) .. ")"
            end,
          }, function(choice)
            vim.api.nvim_win_set_cursor(0, bin.addr2pos(tonumber(choice)))
          end)
        end)
      else
        vim.notify("No occurrence of " .. text .. " found", vim.log.levels.ERROR)
      end
    end)
  end)
end

---Redo toggle
M.refresh = function()
  M.toggle()
  M.toggle()
end

---@type table[nvim-elf-file.Command, string]
M.COMMANDS = {
  ["help"] = "Show keybinds",
  ["toggle"] = "Toggle display based on filetype",
  ["toggle-elf"] = "Toggle readelf display",
  ["toggle-bin"] = "Toggle xxd binary display",
  ["dump"] = "Dump section/symbol/file under cursor",
  ["jump"] = "Jump to an address in a binary file",
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
