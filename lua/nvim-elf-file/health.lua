local M = {}

local function check_options()
  -- local opts = require("nvim-elf-file.config").options

  local ok, err = pcall(function()
    vim.validate({
      --- validate options here...
      -- name = { opts.name, "string" },
    })
  end)

  if not ok then
    vim.health.error("Invalid setup options: " .. err)
  else
    vim.health.ok("opts are correctly set")
  end
end

---This function is used to check the health of the plugin
---It's called by `:checkhealth` command
M.check = function()
  vim.health.start("nvim-elf-file health check")

  check_options()

  -- Add more checks:
  --  - check for requirements
  --  - check for Neovim options (e.g. python support)
  --  - check for other plugins required
  --  - check for LSP setup
  --  ...
end

return M
