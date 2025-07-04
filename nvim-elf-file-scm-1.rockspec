rockspec_format = "3.0"
package = "nvim-elf-file"
version = "scm-1"

test_dependencies = {
  "lua == 5.1",
  "busted == 2.2.0-1",
  "nlua == 0.3.2-1",
  "plenary.nvim == scm-1",
  "luacov == 0.16.0-1",
}

source = {
  url = "git://github.com/jontheburger/" .. package,
}

build = {
  type = "builtin",
}
