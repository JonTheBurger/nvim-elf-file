local M = {}

---Plugin logger
M.log = require("plenary.log").new({
  plugin = "nvim-elf-file",
  level = "trace",
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

---Fills a buffer with the output of a command asynchronously
---@param buf integer Buffer to fill; use vim.api.nvim_get_current_buf() instead of 0
---@param cmd string Executable to run
---@param args string[] Arguments to pass to exe
---@param callback fun(integer) Function to call upon completion; buf passed in.
M.buf_from_cmd_async = function(buf, cmd, args, callback)
  --First wipe the buffer
  vim.api.nvim_set_option_value("readonly", false, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.api.nvim_set_option_value("readonly", true, { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("modified", false, { buf = buf })

  local pipe = vim.loop.new_pipe()

  vim.loop.spawn(cmd, {
    args = args,
    stdio = { nil, pipe, nil },
  }, function()
    pipe:read_stop()
    pipe:close()
    if callback ~= nil then
      vim.schedule(function()
        callback(buf)
      end)
    end
  end)

  pipe:read_start(function(err, data)
    assert(not err, err)
    if data then
      vim.schedule(function()
        vim.api.nvim_set_option_value("readonly", false, { buf = buf })
        vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
        for line in data:gmatch("[^\r\n]+") do
          vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line })
        end
        vim.api.nvim_set_option_value("readonly", true, { buf = buf })
        vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
        vim.api.nvim_set_option_value("modified", false, { buf = buf })
      end)
    end
  end)
end

---Generic in-place async buffer toggle
---@param cmd string Command to run to replace buffer contents
---@param ft string FileType used to store buffer state in is_<ft>_on
---@param callback? fun(integer) Called with arg buffer id when cmd completes
M.toggle = function(cmd, args, ft, callback)
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

    -- Set modified to false (because we just replaced (edited) buffer contents)
    vim.bo.swapfile = false
    local buf = vim.api.nvim_get_current_buf()
    util.buf_from_cmd_async(buf, cmd, args, callback)

    vim.b.nvim_elf_file = {
      buf_state = buf_state,
      [key] = true,
    }
  elseif vim.b.nvim_elf_file[key] == true then
    util.log.trace("toggle " .. key .. " was true")

    -- Save buf_state as vim.cmd.edit will wipe out vim.b
    local buf_state = vim.b.nvim_elf_file.buf_state
    vim.b.nvim_elf_file = { [key] = nil }

    -- Re-invokes this function, so we set [key] to nil first to no-op the run
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

return M
