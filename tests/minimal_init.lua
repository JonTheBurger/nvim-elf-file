local deps = {
  plenary = "https://github.com/nvim-lua/plenary.nvim",
}

for dep, repo in pairs(deps) do
  local dir = ".cache/" .. dep
  local is_not_a_directory = vim.fn.isdirectory(dir) == 0
  if is_not_a_directory then
    print("Cloning " .. repo)
    vim.fn.system({ "git", "clone", repo, dir })
  end
  vim.opt.rtp:append(dir)
end

vim.opt.rtp:append(".")

vim.cmd("runtime plugin/plenary.vim")
if not pcall(require, "luacov") then
  print("Could not require('luacov'); disabling coverage\n")
end
require("nvim-elf-file")
require("plenary.busted")
