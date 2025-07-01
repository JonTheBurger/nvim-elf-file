if vim.b.nvim_elf_file == nil then
  vim.b.nvim_elf_file = { is_bin_on = false }
end

if not vim.b.nvim_elf_file.is_bin_on then
  require("nvim-elf-file.elf").toggle_bin()
end
