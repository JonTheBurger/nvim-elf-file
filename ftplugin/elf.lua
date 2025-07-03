-- Check for magic bytes in case extension isn't enough
if require("nvim-elf-file.elf").is_elf_file() then
  if vim.b.nvim_elf_file == nil then
    vim.b.nvim_elf_file = { is_elf_on = false }
  end

  if not vim.b.nvim_elf_file.is_elf_on then
    require("nvim-elf-file").toggle_elf()
  end
end
