if not vim.g.loaded_nvim_elf_file then
  vim.filetype.add({
    extension = {
      axf = "elf",
      elf = "elf",
    },
    filename = {
      ["a.out"] = "elf",
    },
  })

  vim.api.nvim_create_user_command("ElfFile", function(opts)
    local sub = opts.fargs[1]
    if sub == "toggle" then
      require("nvim-elf-file.elf").toggle()
    elseif sub == "is_elf" then
      local is_elf = require("nvim-elf-file.elf").is_elf_file()
      vim.notify(vim.fn.expand("%") .. (is_elf and " is an ELF file" or " is not an ELF file"))
    end
  end, {
    nargs = "+",
    complete = function(arg_lead, cmd_line, cursor_pos)
      return { "toggle", "is_elf" }
    end,
  })

  vim.keymap.set(
    "n",
    "<Plug>(nvim-elf-file-toggle)",
    require("nvim-elf-file.elf").toggle,
    { noremap = true, desc = "Toggle readelf display" }
  )
end

vim.g.loaded_nvim_elf_file = true
