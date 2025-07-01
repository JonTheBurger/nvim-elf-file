if not vim.g.loaded_nvim_elf_file then
  vim.filetype.add({
    extension = {
      axf = "elf",
      bin = "bin",
      elf = "elf",
      out = "elf",
    },
  })

  vim.api.nvim_create_user_command("ElfFile", function(opts)
    local sub = opts.fargs[1]
    if sub == "toggle_elf" then
      require("nvim-elf-file.elf").toggle_elf()
    elseif sub == "toggle_bin" then
      require("nvim-elf-file.elf").toggle_bin()
    elseif sub == "dump" then
      require("nvim-elf-file.elf").dump()
    end
  end, {
    nargs = "+",
    complete = function() -- arg_lead, cmd_line, cursor_pos
      return { "toggle_elf", "toggle_bin", "dump" }
    end,
  })

  vim.keymap.set(
    "n",
    "<Plug>(nvim-elf-file-toggle-elf)",
    require("nvim-elf-file.elf").toggle_elf,
    { noremap = true, desc = "Toggle readelf display" }
  )
  vim.keymap.set(
    "n",
    "<Plug>(nvim-elf-file-toggle-bin)",
    require("nvim-elf-file.elf").toggle_bin,
    { noremap = true, desc = "Toggle xxd binary display" }
  )
  vim.keymap.set(
    "n",
    "<Plug>(nvim-elf-file-dump)",
    require("nvim-elf-file.elf").dump,
    { noremap = true, desc = "Dump section/symbol/file under cursor" }
  )
end

vim.g.loaded_nvim_elf_file = true
