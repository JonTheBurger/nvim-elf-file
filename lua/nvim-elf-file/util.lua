local M = {}

---Plugin logger
M.log = require("plenary.log").new({
  plugin = "nvim-elf-file",
  level = "trace",
  use_console = false,
  use_file = true,
  file_levels = true,
})

---Gets the restorable state of the current buffer
---@param buf? integer buffer id
---@return nvim-elf-file.BufferState
M.get_buf_state = function(buf)
  buf = buf or 0
  local binary = vim.bo[buf].binary
  local modifiable = vim.bo[buf].modifiable
  local modified = vim.bo[buf].modified
  local readonly = vim.bo[buf].readonly
  local filetype = vim.bo[buf].filetype
  return { binary, modifiable, modified, readonly, filetype }
end

--Sets the restorable state of the current buffer
---@param state nvim-elf-file.BufferState State to restore
---@param buf? integer buffer id
M.set_buf_state = function(state, buf)
  buf = buf or 0
  vim.bo[buf].binary = state.binary
  vim.bo[buf].modifiable = state.modifiable
  vim.bo[buf].modified = state.modified
  vim.bo[buf].readonly = state.readonly
  vim.bo[buf].filetype = state.filetype
end

---Fills a buffer with the output of a command asynchronously
---@param buf integer Buffer to fill; use vim.api.nvim_get_current_buf() instead of 0
---@param cmd string Executable to run
---@param args string[] Arguments to pass to exe
---@param callback fun(integer) Function to call upon completion; buf passed in.
M.buf_from_cmd_async = function(buf, cmd, args, callback)
  --First clear the buffer
  vim.bo[buf].readonly = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.bo[buf].readonly = true
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false

  ---@diagnostic disable-next-line: undefined-field
  local pipe = vim.loop.new_pipe()

  ---@diagnostic disable-next-line: undefined-field
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
        vim.bo[buf].readonly = false
        vim.bo[buf].modifiable = true
        for line in data:gmatch("[^\r\n]+") do
          vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line })
        end
        vim.bo[buf].readonly = true
        vim.bo[buf].modifiable = false
        vim.bo[buf].modified = false
      end)
    end
  end)
end

---Generic in-place async buffer toggle
---@param cmd string Command to run to replace buffer contents
---@param ft string FileType used to store buffer state in is_<ft>_on
---@param callback? fun(integer) Called with arg buffer id when cmd completes
M.toggle = function(cmd, args, ft, callback)
  local buf = vim.api.nvim_get_current_buf()
  local util = require("nvim-elf-file.util")
  local key = "is_" .. ft .. "_on"

  -- `is_<ft>_on` variables are used to determine if it's in a "virtual" file
  -- mode like `toggle_bin` mode. Note that many vim functions clear `vim.b`,
  -- such as `vim.fn.edit`. To account for cases where `is_<ft>_on` is set to
  -- `nil`, a `nil` value is treated as a no-op by the toggle functions.
  if vim.b[buf].nvim_elf_file == nil then
    ---@type nvim-elf-file.BufferOpts
    vim.b[buf].nvim_elf_file = {}
  end

  if vim.b[buf].nvim_elf_file[key] == false then
    util.log.trace("toggle " .. key .. " was false")

    -- Store previous state, temporarily make buffer writable
    local buf_state = util.get_buf_state(buf)
    vim.bo[buf].modifiable = true
    vim.bo[buf].readonly = false

    util.log.info(cmd .. " " .. table.concat(args, " "))

    -- Set modified to false (because we just replaced (edited) buffer contents)
    vim.bo[buf].swapfile = false
    util.buf_from_cmd_async(buf, cmd, args, callback)

    vim.b[buf].nvim_elf_file = {
      buf_state = buf_state,
      [key] = true,
    }
  elseif vim.b[buf].nvim_elf_file[key] == true then
    util.log.trace("toggle " .. key .. " was true")

    -- Save buf_state as vim.cmd.edit will wipe out vim.b
    local buf_state = vim.b[buf].nvim_elf_file.buf_state
    vim.b[buf].nvim_elf_file = { [key] = nil }

    -- Re-invokes this function, so we set [key] to nil first to no-op the run
    vim.cmd.edit("%")

    util.set_buf_state(buf_state or {}, buf)
    vim.b[buf].nvim_elf_file = { [key] = false }
  else
    -- Commands like vim.cmd.edit(...) re-invoke this function with vim.b cleared.
    -- This causes vim.b.nvim_elf_file[key] to be `nil`.
    -- We use the nil case as a no-op to prevent infinite recursion
    util.log.trace("toggle " .. key .. " was nil")
  end
end

---Gets the editable width of the current window in characters
---@return integer width of the window that is usable
M.get_win_width = function()
  local win = vim.api.nvim_get_current_win()
  local win_info = vim.fn.getwininfo(win)[1]
  local width = win_info.width - win_info.textoff
  return width
end

return M
