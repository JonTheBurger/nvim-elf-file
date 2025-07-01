local M = {}

M.log = require("plenary.log").new({
  plugin = "nvim-elf-file",
  level = "info",
  use_console = false,
  use_file = true,
  file_levels = true,
})

---Finds the index of an ascii character in a string
---@param str string to search
---@param char string character to search for
---@param idx? integer start index; defaults to 1
---@return integer? index of char, or nil if not found
M.find_char = function(str, char, idx)
  local ascii = char:byte(1)
  idx = idx or 1
  for i = idx, #str, 1 do
    if str:byte(i) == ascii then
      return i
    end
  end
  return nil
end

---Finds the index of the first ascii character in a string not matching char
---@param str string to search
---@param char string character to skip
---@param idx? integer start index; defaults to 1
---@return integer? index of char, or nil if not found
M.skip_char = function(str, char, idx)
  local ascii = char:byte(1)
  idx = idx or 1
  for i = idx, #str, 1 do
    if str:byte(i) ~= ascii then
      return i
    end
  end
  return nil
end

---Remove surrounding whitespace from a string
---@param str string Original string
---@return string string with surrounding whitespace removed
M.trim = function(str)
  return str:match("^%s*(.-)%s*$")
end

---Gets the restorable state of the current buffer
---@return nvim-elf-file.BufferState
M.get_buf_state = function()
  local binary = vim.bo.binary
  local modifiable = vim.bo.modifiable
  local modified = vim.bo.modified
  local readonly = vim.bo.readonly
  local filetype = vim.bo.filetype
  return { binary, modifiable, modified, readonly, filetype }
end

--Sets the restorable state of the current buffer
---@param state nvim-elf-file.BufferState
M.set_buf_state = function(state)
  vim.bo.binary = state.binary
  vim.bo.modifiable = state.modifiable
  vim.bo.modified = state.modified
  vim.bo.readonly = state.readonly
  vim.bo.filetype = state.filetype
end

return M
