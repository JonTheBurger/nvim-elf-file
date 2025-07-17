local M = {}

--- 8 digits + colon + space
M.ADDRESS_HEADER_LEN = 8 + 1 + 1

M.NIBBLES_PER_BYTE = 2

---Given an xxd line like the following, determine how many columns to use:
---00000000: 0201 0100 0000 0000  ........
---^~~~~~~~~^ addr_len = address + colon + space (8 + 1 + 1)
---  +1 space before the text ~~~^
---          ^~~^ group = 2 bytes
---          ^~~~^ group_len = nibbles + space + (2 bytes * 2 nibbles + 1)
---      +1 char for every group  ^^
---@param group integer Bytes per group
---@param width integer Width of window in characters
---@param bytes_per_line? integer|'"auto"' Bytes per line, auto to calculate
---@return integer Number of bytes shown per line of xxd output
M.get_bytes_per_line = function(group, width, bytes_per_line)
  local util = require("nvim-elf-file.util")
  local cols

  if bytes_per_line == nil or bytes_per_line == "auto" then
    -- Address header + 1 space before text at the end of the line
    local header_width = M.ADDRESS_HEADER_LEN + 1
    width = width - header_width

    -- groups of bytes * 2 nibbles + 1 space separator + 1 char per byte in group
    local group_len = group * M.NIBBLES_PER_BYTE + 1 + group

    cols = width / group_len
    util.log.trace({
      group = group,
      header_width = header_width,
      width = width,
      group_len = group_len,
      cols = cols,
      bytes_per_line = bytes_per_line,
    })
  else
    ---@diagnostic disable-next-line=param-type-mismatch
    cols = bytes_per_line
  end
  -- xxd columns are the number of bytes to display, so scale by groups (bytes) in the line
  cols = math.floor(cols) * group ---@diagnostic disable-line=param-type-mismatch
  return cols
end

---Determines the nearest byte offset for the xxd cursor
---@param line integer Line in buffer
---@param col integer Column in buffer
---@param width integer (Original) width of the buffer
---@return integer address offset of the closest byte under cursor
M.pos2addr = function(line, col, width)
  local util = require("nvim-elf-file.util")
  local opt = require("nvim-elf-file.config").options
  local bytes_per_group = opt.xxd.bytes_per_column

  local bytes_per_line = M.get_bytes_per_line(bytes_per_group, width)
  local chars_per_group = bytes_per_group * M.NIBBLES_PER_BYTE + 1

  local address
  local line_bytes = bytes_per_line * (line - 1)

  -- +2: +1 for space before text start, +1 to put cursor on text start
  local groups_per_line = bytes_per_line / bytes_per_group
  local text_start = M.ADDRESS_HEADER_LEN + (chars_per_group * groups_per_line) + 2

  if col >= text_start then
    address = line_bytes + (col - text_start)
  else
    -- Minus 1 more because columns are 1-indexed
    col = col - M.ADDRESS_HEADER_LEN - 1
    if col < 0 then
      col = 0
    end
    local group_num = math.floor((col + chars_per_group) / chars_per_group) - 1 -- -1 for zero indexing
    local group_nibble = col - (group_num * chars_per_group)
    local col_bytes = (group_num * bytes_per_group) + math.floor(group_nibble / M.NIBBLES_PER_BYTE)
    util.log.trace({
      group_num = group_num,
      group_nibble = group_nibble,
      col_bytes = col_bytes,
    })
    address = line_bytes + col_bytes
  end

  util.log.trace({
    bytes_per_group = bytes_per_group,
    bytes_per_line = bytes_per_line,
    chars_per_group = chars_per_group,
    line_bytes = line_bytes,
    groups_per_line = groups_per_line,
    text_start = text_start,
    address = address,
  })
  return address
end

M.addr2pos = function(address)
  local util = require("nvim-elf-file.util")
  local opt = require("nvim-elf-file.config").options
  local width = vim.b.nvim_elf_file.width
  local bytes_per_group = opt.xxd.bytes_per_column
  local bytes_per_line = M.get_bytes_per_line(bytes_per_group, width)
  local chars_per_group = bytes_per_group * M.NIBBLES_PER_BYTE + 1

  local byte_offset = address % bytes_per_line
  local line = (address - byte_offset) / bytes_per_line
  local col = M.ADDRESS_HEADER_LEN + math.floor(byte_offset / bytes_per_group * chars_per_group)

  util.log.trace({
    address = address,
    bytes_per_group = bytes_per_group,
    bytes_per_line = bytes_per_line,
    chars_per_group = chars_per_group,
    byte_offset = byte_offset,
    line = line + 1,
    col = col,
  })

  return { line + 1, col }
end

return M
