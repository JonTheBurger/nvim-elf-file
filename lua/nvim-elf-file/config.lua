local M = {}
local tbl = require("plenary.tbl")

---Read-only default options.
---WARNING: When changing this table, also be sure to update `README.md` and `make docs`
---@type nvim-elf-file.UserOptions
M.defaults = {
  -- Path to single readelf program name / executable path,
  -- readelf = "/usr/bin/readelf",

  -- Or a function that picks readelf based on machine (see table below)
  -- An empty string should return a default implementation
  ---@param machine string
  readelf = function(machine)
    if machine == "ARM" then
      return "arm-none-eabi-readelf"
    end
    return "readelf"
  end,

  -- Same thing as readelf, but for objdump
  ---@param machine string
  objdump = function(machine)
    if machine == "ARM" then
      return "arm-none-eabi-objdump"
    end
    return "objdump"
  end,

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
    ["<F1>"] = "hover",
    ["<F2>"] = "search-text",
    ["<F3>"] = "search-bin",
    ["<F4>"] = "jump",
    ["<F5>"] = "refresh",
    ["<F12>"] = "dump",
  },

  -- Set to false to disable automatic conversion of the filetype's buffer
  automatic = {
    elf = true,
    bin = true,
  },

  -- What to do when a e.g. disassembled function buffer goes out of view.
  -- By default, it is wiped out.
  bufhidden = "wipe",

  -- Verbosity of `vim.fn.stdpath("data") .. "/nvim-elf-file.log"`
  log_level = "trace",
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
  if type(merged.readelf) == "string" then
    options.readelf = function(_)
      return merged.readelf
    end
  end
  if type(merged.objdump) == "string" then
    options.objdump = function(_)
      return merged.objdump
    end
  end

  setmetatable(options, self)
  return options
end

---Apply configuration settings to the rest of the plugin's globals
function Options:apply()
  local util = require("nvim-elf-file.util")
  util.log.level = self.log_level

  if self.refresh then
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

    -- TODO: Update
    -- vim.validate("xxd", opts.xxd, is_executable, "executable xxd")

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

    vim.validate("bufhidden", opts.bufhidden, function(k)
      return api.BUF_HIDDEN[k] ~= nil
    end, '"' .. table.concat(iter.iter(api.BUF_HIDDEN):tolist(), '"|"') .. '"')

    vim.validate("log_level", opts.log_level, function(k)
      return iter.iter(api.LOG_LEVELS):any(function(e)
        return e == k
      end)
    end, '"' .. table.concat(api.LOG_LEVELS, '"|"') .. '"')
  end)
  return ok, err
end

return M
