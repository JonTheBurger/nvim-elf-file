local M = {}

---This function is used to check the health of the plugin
---It's called by `:checkhealth` command
M.check = function()
  vim.health.start("nvim-elf-file health check")

  -- Check nvim version
  local v = vim.version()
  local major, minor, patch = 0, 11, 0
  if
    (v.major < major)
    or (v.major == major) and (v.minor < minor)
    or (v.major == major) and (v.minor == minor) and (v.patch < patch)
  then
    vim.health.error(
      "Neovim version is too old!",
      "Please upgrade to " .. tostring(major) .. "." .. tostring(minor) .. "." .. tostring(patch)
    )
  else
    vim.health.ok("Neovim version is up to date")
  end

  -- Check dependencies
  local ok, err = pcall(function()
    require("plenary")
  end)
  if not ok then
    vim.health.error(
      'Missing "plenary": ' .. err,
      'Please add "plenary" to "dependencies"/"requires"/"depends" for your plugin manager'
    )
  else
    vim.health.ok('Dependency: "plenary" found')
  end

  -- Check config
  local config = require("nvim-elf-file.config")
  local opts = config.options
  ok, err = config.validate(opts.user)
  if not ok then
    vim.health.error("Invalid setup options: " .. err)
  else
    vim.health.ok("Setup options are valid")
  end
end

return M
