local M = {}
local tbl = require("plenary.tbl")

---Read-only default options.
---WARNING: When changing this table, also be sure to update `README.md` and `make docs`
---@type nvim-elf-file.UserOptions
M.defaults = {
  -- Path to single readelf program name / executable path,
  -- readelf = "/usr/bin/readelf",

  -- Or a function that picks readelf based on machine (see table below)
  -- nil should return a default implementation
  ---@param machine? string
  readelf = function(machine)
    if machine == "ARM" then
      return "arm-none-eabi-readelf"
    end
    return "readelf"
  end,

  -- Same thing as readelf, but for objdump
  ---@param machine? string
  objdump = function(machine)
    if machine == "ARM" then
      return "arm-none-eabi-objdump"
    end
    return "objdump"
  end,

  -- Name of strings command
  strings = "strings",

  -- Name of ripgrep command
  rg = "rg",

  -- Name of binary dumping program (not machine-dependent)
  xxd = {
    -- Name of or path to xxd executable
    executable = "xxd",
    -- Number of bytes to group in a column (2 nibbles per-byte)
    bytes_per_column = 2,
    -- Number of bytes to group in a line ("auto" to fill the line)
    bytes_per_line = "auto",
    -- How to display the address ("hexadecimal" or "decimal")
    address_format = "hexadecimal",
    -- Replace consecutive lines of all '0' with a '*'
    skip_zeros = false,
    -- Use uppercase letters for hexadecimal
    uppercase = false,
  },

  -- nvim-elf-file buffer-specific keymaps.
  -- Each entry is a <Plug>(nvim-elf-file-<command>)
  -- See list of commands in "Usage" below
  keymaps = {
    ["?"] = "help",
    ["<CR>"] = "dump",
    ["<S-K>"] = "hover",
    ["sj"] = "jump",
    ["sb"] = "search-bin",
    ["st"] = "search-text",
    ["ss"] = "search-strings",
    ["<F1>"] = "hover",
    ["<F4>"] = "jump",
    ["<F5>"] = "refresh",
    ["<F12>"] = "dump",
  },

  -- Set to false to disable automatic conversion of the filetype's buffer
  automatic = {
    elf = true,
    bin = true,
    -- Automatically refresh the render when window size changes
    refresh = false,
  },

  -- List of registers to yank strings to
  yank_registers = { "0", "'", '"' },

  -- What to do when a e.g. disassembled function buffer goes out of view.
  -- By default, it is wiped out.
  bufhidden = "wipe",

  -- Verbosity of `vim.fn.stdpath("data") .. "/nvim-elf-file.log"`
  log_level = "info",
}
tbl.freeze(M.defaults)

---Options passed in by the user.
---@type nvim-elf-file.UserOptions
M.user = {}

---@class nvim-elf-file.Options
local Options = {}
Options.__index = Options
M.Options = Options

---Construct a new options
---@param opts nvim-elf-file.UserOptions
---@return nvim-elf-file.Options
function Options:new(opts)
  local merged = vim.tbl_deep_extend("force", {}, M.defaults, opts)
  ---@type nvim-elf-file.Options
  local options = vim.deepcopy(merged, true)

  options.user = merged

  setmetatable(options, self)
  return options
end

---Apply configuration settings to the rest of the plugin's globals
function Options:apply()
  local util = require("nvim-elf-file.util")
  util.log.level = self.log_level

  if self.automatic.refresh then
    vim.api.nvim_create_augroup("nvim-elf-file", { clear = true })
    vim.api.nvim_create_autocmd({ "WinResized" }, {
      group = "nvim-elf-file",
      callback = function()
        if vim.b.nvim_elf_file and vim.b.nvim_elf_file.is_bin_on then
          require("nvim-elf-file").refresh()
        end
      end,
    })
  end
end

---Checks ELF headers to select readelf
---@param file? string ELF file to read header
---@return string Architecture-specific readelf command
function Options:get_readelf(file)
  if type(self.readelf) == "string" then
    ---@diagnostic disable-next-line: return-type-mismatch
    return self.readelf
  end

  if not file then
    file = vim.fn.expand("%")
  end

  local exe = self.readelf()
  local output = vim.fn.system({
    exe,
    "--wide",
    "--file-header",
    file,
  })

  local header = require("nvim-elf-file.elf").parse_header(output)
  if header ~= nil then
    exe = self.readelf(header.machine)
  end
  return exe
end

---Checks ELF headers to select objdump
---@param file? string ELF file to read header
---@return string Architecture-specific objdump command
function Options:get_objdump(file)
  if type(self.objdump) == "string" then
    ---@diagnostic disable-next-line: return-type-mismatch
    return self.objdump
  end

  if not file then
    file = vim.fn.expand("%")
  end
  local readelf = self.readelf()
  local output = vim.fn.system({
    readelf,
    "--wide",
    "--file-header",
    file,
  })

  local header = require("nvim-elf-file.elf").parse_header(output)
  if header ~= nil then
    return self.objdump(header.machine)
  end
  return self.objdump()
end

---@type nvim-elf-file.Options
M.options = Options:new(M.defaults)

---Set up the plugin with custom settings
---@param opts? nvim-elf-file.UserOptions Plugin options
M.setup = function(opts)
  M.user = opts or {}
  local config = vim.tbl_deep_extend("force", {}, M.defaults, M.user)

  local ok, err = M.validate(config)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
    return err
  end

  M.options = Options:new(config)
  M.options:apply()
end

---Checks that the user config is valid
---@param opts nvim-elf-file.UserOptions Plugin options
---@return boolean, string? Success + error message
M.validate = function(opts)
  local api = require("nvim-elf-file")
  local iter = require("plenary.iterators")
  local is_executable = function(exe)
    return type(exe) == "string" and vim.fn.executable(exe) == 1
  end
  local is_in = function(list)
    return function(k)
      return iter.iter(list):any(function(e)
        return e == k
      end)
    end
  end
  local list2str = function(list)
    return '"' .. table.concat(list, '"|"') .. '"'
  end

  local ok, err = pcall(function()
    if type(opts.readelf) == "string" then
      vim.validate("readelf", opts.readelf, is_executable, "executable default readelf")
    else
      vim.validate("readelf()", opts.readelf(""), is_executable, "executable default readelf")
    end

    if type(opts.objdump) == "string" then
      vim.validate("objdump", opts.objdump, is_executable, "executable default objdump")
    else
      vim.validate("objdump()", opts.objdump(""), is_executable, "executable default objdump")
    end

    vim.validate("strings", opts.strings, is_executable, "executable strings")
    vim.validate("rg", opts.rg, is_executable, "executable rg")

    vim.validate("xxd", opts.xxd, "table")
    vim.validate("xxd.executable", opts.xxd.executable, is_executable, "executable xxd")
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.validate("xxd.bytes_per_column", opts.xxd.bytes_per_column, "number", function(v)
      return v > 0 and math.floor(v) == v
    end, "positive integer")
    vim.validate("xxd.bytes_per_line", opts.xxd.bytes_per_line, function(v)
      if type(v) == "number" then
        return (v > 0 and math.floor(v) == v)
      elseif type(v) == "string" then
        return (v == "auto")
      else
        return false
      end
    end, "positive integer or 'auto'")
    vim.validate("xxd.address_format", opts.xxd.address_format, is_in(api.ADDR_FMT), list2str(api.ADDR_FMT))
    vim.validate("xxd.skip_zeros", opts.xxd.skip_zeros, "boolean")
    vim.validate("xxd.uppercase", opts.xxd.uppercase, "boolean")

    vim.validate("keymaps", opts.keymaps, "table")
    for key, value in pairs(opts.keymaps) do
      vim.validate("keymaps[" .. tostring(key) .. "]", key, "string")
      vim.validate('keymaps["' .. tostring(key) .. '"] = ' .. tostring(value), value, "string")
      vim.validate('keymaps["' .. tostring(key) .. '"] = "' .. tostring(value) .. '"', value, function(k)
        return api.COMMANDS[k] ~= nil
      end, '"' .. table.concat(iter.iter(api.COMMANDS):tolist(), '"|"') .. '"')
    end

    vim.validate("automatic", opts.automatic, "table")
    for key, value in pairs(opts.automatic) do
      vim.validate("automatic[" .. tostring(key) .. "]", key, "string")
      vim.validate('automatic["' .. tostring(key) .. '"] = ' .. tostring(value), value, "boolean")
    end

    vim.validate("bufhidden", opts.bufhidden, is_in(api.BUF_HIDDEN), list2str(api.BUF_HIDDEN))
    vim.validate("log_level", opts.log_level, is_in(api.LOG_LEVELS), list2str(api.LOG_LEVELS))
  end)
  return ok, err
end

return M
