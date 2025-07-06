require("luacov")
-- if jit then jit.off(true, true) end
-- require("luacov")
-- require("luacov.runner")(".luacov")
-- vim.opt.rtp:append(".")

local api = require("nvim-elf-file")
local config = require("nvim-elf-file.config")
local elf = require("nvim-elf-file.elf")
local util = require("nvim-elf-file.util")

describe("nvim-elf-file.config", function()
  describe("setup", function()
    it("works with default", function()
      local err = api.setup()
      assert(not err, err)
    end)

    it("sets log level", function()
      ---@type nvim-elf-file.UserOptions
      local opts = {
        log_level = "error",
      }

      util.log.level = "info"
      local err = api.setup(opts)

      assert(not err, err)
      assert(util.log.level == "error")
    end)

    it("converts readelf string to function", function()
      ---@type nvim-elf-file.UserOptions
      local opts = {
        readelf = "readelf",
      }

      local err = api.setup(opts)
      local options = config.options

      assert(not err, err)
      assert(options.readelf("") == "readelf", "Didn't return hard-coded readelf")
      assert(options.readelf("ARM") == "readelf", "Didn't return hard-coded readelf")
    end)

    it("converts objdump string to function", function()
      ---@type nvim-elf-file.UserOptions
      local opts = {
        objdump = "objdump",
      }

      local err = api.setup(opts)
      local options = config.options

      assert(not err, err)
      assert(options.objdump("") == "objdump", "Didn't return hard-coded objdump")
      assert(options.objdump("ARM") == "objdump", "Didn't return hard-coded objdump")
    end)
  end)

  describe("validate", function()
    it("checks readelf is executable", function()
      ---@type nvim-elf-file.UserOptions
      local opts = {
        readelf = "dummy-readelf",
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find("executable default readelf"), err)
    end)

    it("checks objdump is executable", function()
      ---@type nvim-elf-file.UserOptions
      local opts = {
        objdump = "dummy-objdump",
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find("executable default objdump"), err)
    end)

    it("checks xxd is executable", function()
      ---@type nvim-elf-file.UserOptions
      local opts = {
        xxd = "dummy-xxd",
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find("executable xxd"), err)
    end)

    it("checks keymaps is a table", function()
      local opts = {
        keymaps = "WRONG",
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find("keymaps: expected table"), err)
    end)

    it("checks keymaps is a table[string]", function()
      local opts = {
        keymaps = {
          [1] = "toggle-bin",
        },
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find("keymaps%[1%]: expected string"), err)
    end)

    it("checks keymaps is a table[string, string]", function()
      local opts = {
        keymaps = {
          ["<cr>"] = 1,
        },
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find('keymaps%["<cr>"%] = 1: expected'), err)
    end)

    it("checks keymaps is a table[string, command]", function()
      local opts = {
        keymaps = {
          ["<cr>"] = "WRONG",
        },
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find('keymaps%["<cr>"%] = "WRONG": expected'), err)
    end)

    it("checks bufhidden is a BufHidden", function()
      local opts = {
        bufhidden = "WRONG",
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find("bufhidden: expected"), err)
    end)

    it("checks log_level is a LogLevel", function()
      local opts = {
        log_level = "WRONG",
      }
      opts = vim.tbl_deep_extend("force", {}, config.defaults, opts)

      local ok, err = config.validate(opts)

      assert(not ok and err ~= nil and err:find("log_level: expected"), err)
    end)
  end)
end)

describe("nvim-elf-file.elf", function()
  describe("is_elf_file", function()
    it("returns false for non-elf", function()
      local is_elf = elf.is_elf_file("Makefile")
      assert(not is_elf)
    end)

    it("returns true for elf", function()
      local is_elf = elf.is_elf_file(vim.fn.exepath("make"))
      assert(is_elf)
    end)
  end)

  describe("is_section_line", function()
    it("identifies bracket with space", function()
      local line = "  [ 4] .note.ABI-tag     NOTE            000000000000038c 00038c 000020 00   A  0   0  4"
      assert(elf.is_section_line(line), line)
    end)

    it("identifies missing flags", function()
      local line = "  [29] .shstrtab         STRTAB          0000000000000000 03ee3c 00011d 00      0   0  1"
      assert(elf.is_section_line(line), line)
    end)

    it("skips invalid line", function()
      local line = "    11: 0000000000000000     0 FUNC    GLOBAL DEFAULT  UND __errno_location@GLIBC_2.2.5 (3)"
      assert(not elf.is_section_line(line), line)
    end)
  end)

  describe("parse_header", function()
    it("parses header", function()
      local output = [[
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              DYN (Position-Independent Executable file)
  Machine:                           Advanced Micro Devices X86-64
  Version:                           0x1
  Entry point address:               0xc2c0
  Start of program headers:          64 (bytes into file)
  Start of section headers:          257888 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           56 (bytes)
  Number of program headers:         13
  Size of section headers:           64 (bytes)
  Number of section headers:         30
  Section header string table index: 29
]]
      local header = elf.parse_header(output)

      assert(header, "not nil")
      assert(header.machine == "Advanced Micro Devices X86-64", header.machine)
      assert(header.type == "DYN (Position-Independent Executable file)", header.type)
    end)

    it("returns nil on error", function()
      local output = {
        "ELF Header:",
        "  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00",
        "  Class:                             ELF64",
        "  Data:                              2's complement, little endian",
        "  Version:                           1 (current)",
        "  OS/ABI:                            UNIX - System V",
        "  ABI Version:                       0",
        "  Type:                              DYN (Position-Independent Executable file)",
        "  Version:                           0x1",
        "  Entry point address:               0xc2c0",
        "  Start of program headers:          64 (bytes into file)",
        "  Start of section headers:          257888 (bytes into file)",
        "  Flags:                             0x0",
        "  Size of this header:               64 (bytes)",
        "  Size of program headers:           56 (bytes)",
        "  Number of program headers:         13",
        "  Size of section headers:           64 (bytes)",
        "  Number of section headers:         30",
        "  Section header string table index: 29",
      }
      assert(not elf.parse_header(output), "missing 'Machine'")
    end)
  end)

  describe("parse_section", function()
    it("parses bracket with space", function()
      local line = "  [ 4] .note.ABI-tag     NOTE            000000000000038c 00038c 000020 00   A  0   0  4"

      local section = elf.parse_section(line)

      assert(section, "not nil")
      assert(section.id, "not nil")
      assert(section.kind, "not nil")
      assert(section.name, "not nil")
      assert(section.id == 4, section.id)
      assert(section.kind == "NOTE", section.kind)
      assert(section.name == ".note.ABI-tag", section.name)
    end)

    it("parses missing flags", function()
      local line = "  [29] .shstrtab         STRTAB          0000000000000000 03ee3c 00011d 00      0   0  1"

      local section = elf.parse_section(line)

      assert(section, "not nil")
      assert(section.id, "not nil")
      assert(section.kind, "not nil")
      assert(section.name, "not nil")
      assert(section.id == 29, section.id)
      assert(section.kind == "STRTAB", section.kind)
      assert(section.name == ".shstrtab", section.name)
    end)

    it("returns nil on error", function()
      local line = "  [hi] .shstrtab         STRTAB          0000000000000000 03ee3c 00011d 00      0   0  1"
      assert(not elf.parse_section(line), line)

      line = "  [29] .strtab ~~invalid~~"
      assert(not elf.parse_section(line), line)

      line = "  [29] .strtab"
      assert(not elf.parse_section(line), line)

      line = "  [29]"
      assert(not elf.parse_section(line), line)

      line = ""
      assert(not elf.parse_section(line), line)
    end)
  end)

  describe("parse_symbol", function()
    it("parses line with version", function()
      local line = "   297: 0000000000015070   129 FUNC    GLOBAL DEFAULT  UND lstat@GLIBC_2.33 (9)"

      local symbol = elf.parse_symbol(line)

      assert(symbol, "not nil")
      assert(symbol.id, "not nil")
      assert(symbol.start, "not nil")
      assert(symbol.stop, "not nil")
      assert(symbol.kind, "not nil")
      assert(symbol.bind, "not nil")
      assert(symbol.visibility, "not nil")
      assert(symbol.section_idx, "not nil")
      assert(symbol.name, "not nil")

      assert(symbol.id == 297, tostring(symbol.id))
      assert(symbol.start == 0x15070, tostring(symbol.start))
      assert(symbol.stop == 0x15070 + 129, tostring(symbol.stop))
      assert(symbol.kind == "FUNC", tostring(symbol.kind))
      assert(symbol.bind == "GLOBAL", tostring(symbol.bind))
      assert(symbol.visibility == "DEFAULT", tostring(symbol.visibility))
      assert(symbol.section_idx == "UND", tostring(symbol.section_idx))
      assert(symbol.name == "lstat@GLIBC_2.33 (9)", tostring(symbol.name))
    end)

    it("returns nil on error", function()
      local line = "   297: 0000000000000000     0 FUNC    GLOBAL DEFAULT"
      assert(not elf.parse_symbol(line), line)

      line = "   297: 0000000000000000     0 FUNC    GLOBAL"
      assert(not elf.parse_symbol(line), line)

      line = "   297: 0000000000000000     0 FUNC"
      assert(not elf.parse_symbol(line), line)

      line = "   297: 0000000000000000     0"
      assert(not elf.parse_symbol(line), line)

      line = "   297: 0000000000000000"
      assert(not elf.parse_symbol(line), line)

      line = "   297:"
      assert(not elf.parse_symbol(line), line)

      line = ""
      assert(not elf.parse_symbol(line), line)
    end)
  end)
end)
