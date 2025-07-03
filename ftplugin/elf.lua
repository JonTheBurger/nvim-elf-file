-- Check for magic bytes in case extension isn't enough
if require("nvim-elf-file.config").options.automatic["elf"] and require("nvim-elf-file").is_elf_file() then
  require("nvim-elf-file").toggle_elf()
end
