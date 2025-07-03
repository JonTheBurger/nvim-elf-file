local M = {}

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
  xxd = "xxd",

  -- nvim-elf-file buffer-specific keymaps.
  -- Each entry is a <Plug>(nvim-elf-file-<command>)
  -- See list of commands in "Usage" below
  keymaps = {
    ["<cr>"] = "dump",
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
  log_level = "info",
}

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
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  M.options = Options:new(config)
  M.options:apply()
end

---Checks that the user config is valid
---@param opts nvim-elf-file.UserOptions Plugin options
---@return boolean, string Success + error message
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

    vim.validate("xxd", opts.xxd, is_executable, "executable xxd")

    vim.validate("keymaps", opts.keymaps, "table")
    for key, value in pairs(opts.keymaps) do
      vim.validate('keymaps["' .. tostring(key) .. '"]', key, "string")
      vim.validate('keymaps["' .. tostring(key) .. '"] = "' .. tostring(value) .. '"', value, "string")
      vim.validate('keymaps["' .. tostring(key) .. '"] = "' .. tostring(value) .. '"', value, function(k)
        return api.COMMANDS[k] ~= nil
      end, '"' .. table.concat(api.COMMANDS, '"|"') .. '"')
    end

    vim.validate("automatic", opts.automatic, "table")
    for key, value in pairs(opts.automatic) do
      vim.validate('automatic["' .. tostring(key) .. '"]', key, "string")
      vim.validate('automatic["' .. tostring(key) .. '"] = "' .. tostring(value) .. '"', value, "boolean")
    end

    vim.validate("bufhidden", opts.bufhidden, function(k)
      return api.BUF_HIDDEN[k] ~= nil
    end, '"' .. table.concat(api.BUF_HIDDEN, '"|"') .. '"')

    vim.validate("log_level", opts.log_level, function(k)
      return iter.iter(api.LOG_LEVELS):any(function(e)
        return e == k
      end)
    end, '"' .. table.concat(api.LOG_LEVELS, '"|"') .. '"')
  end)
  return ok, tostring(err)
end

return M
