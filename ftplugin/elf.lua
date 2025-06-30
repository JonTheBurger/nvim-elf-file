local elf = require("nvim-elf-file.elf")
elf.toggle()

vim.keymap.set("n", "<Plug>(nvim-elf-file-disassemble)", elf.disassemble, { noremap = true, desc = "Disassemble" })
