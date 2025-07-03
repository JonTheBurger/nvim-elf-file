# nvim-elf-file

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ellisonleao/nvim-plugin-template/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

--------------------------------------------------------------------------------

A simple plugin to browse `.elf` and `bin` file contents in the style of
[pi_zip].

--------------------------------------------------------------------------------

## Features

TODO: gifs!

--------------------------------------------------------------------------------

## Installation

Requires:

- neovim `0.11.0`+
- [plenary.nvim]

[lazy.nvim]

```lua
{
  "jontheburger/nvim-elf-file",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
}
```

[packer]:

```lua
{
  "jontheburger/nvim-elf-file", 
  requires = { "nvim-lua/plenary.nvim" },
  opt = true,
  config = function()
    require("nvim-elf-file").setup({})
  end
}
```

[mini.deps]:

```lua
add({
  source = "jontheburger/nvim-elf-file",
  depends = { "nvim-lua/plenary.nvim" },
  checkout = ""
})
```

--------------------------------------------------------------------------------

## Configuration

The following the default `opts`:

```lua
---@type nvim-elf-file.UserOptions
opts = {
  -- Path to single readelf program name / executable path,
  -- readelf = "/usr/bin/readelf",

  -- Or a function that picks readelf based on machine (see table below)
  -- An empty string should return a default implementation
  ---@param machine string
  readelf = function(machine)
    if machine == "ARM" then
      return "arm-none-eabi-readelf"
    end
    return "readelf"
  end,

  -- Same thing as readelf, but for objdump
  ---@param machine string
  objdump = function(machine)
    if machine == "ARM" then
      return "arm-none-eabi-objdump"
    end
    return "objdump"
  end,

  -- Name of binary dumping program (not machine-dependent)
  xxd = "xxd",

  -- nvim-elf-file buffer-specific keymaps.
  -- Each entry is a <Plug>(nvim-elf-file-<command>)
  -- See list of commands in "Usage" below
  keymaps = {
    ["<cr>"] = "dump",
  },

  -- Set to false to disable automatic conversion of the filetype's buffer
  automatic = {
    elf = true,
    bin = true,
  },

  -- What to do when a e.g. disassembled function buffer goes out of view.
  -- By default, it is wiped out.
  bufhidden = "wipe",

  -- Verbosity of `vim.fn.stdpath("data") .. "/nvim-elf-file.log"`
  log_level = "info",
}
```

Some common machines include:

| Machine (from `readelf`)        | Architecture         |
| ------------------------------- | -------------------- |
| `Advanced Micro Devices X86-64` | 64-bit x86 (x86\_64) |
| `Intel 80386`                   | 32-bit x86           |
| `ARM`                           | 32-bit ARM           |
| `AArch64`                       | 64-bit ARM           |
| `MIPS R3000`                    | MIPS                 |
| `RISC-V`                        | RISC-V               |
| `PowerPC`                       | PowerPC              |
| `SPARC`                         | SPARC                |

--------------------------------------------------------------------------------

## Usage

This plugin provides the `ElfFile` EX Command with sub-commands:

| Command              | Description                                                         |
| -------------------- | ------------------------------------------------------------------- |
| `ElfFile toggle bin` | Enables/Disables binary byte viewer.                                |
| `ElfFile toggle elf` | Enables/Disables readelf view for `.elf` files.                     |
| `ElfFile dump`       | Dumps the section or symbol under the current line for `.elf` files |

This plugin also provides `<Plug>(nvim-elf-file-<command>)` mappings:

| Mapping                            | Command              |
| ---------------------------------- | -------------------- |
| `<Plug>(nvim-elf-file-toggle-bin)` | `ElfFile toggle_bin` |
| `<Plug>(nvim-elf-file-toggle-elf)` | `ElfFile toggle_elf` |
| `<Plug>(nvim-elf-file-dump)`       | `ElfFile dump`       |

This plugin also keeps the lua API located in `require("nvim-elf-file")` stable:

| Function                           | Command                                                                         |
| ---------------------------------- | ------------------------------------------------------------------------------- |
| `setup(opts)`                      | `Set up the plugin with custom settings`                                        |
| `is_elf_file(file)`                | `Checks if thebufnr/string path is an ELF file by checking for the magic bytes` |
| `toggle_elf()`                     | `Uses readelf to dump the elf file contents into a readonly buffer`             |
| `toggle_bin()`                     | `Uses xxd dump the current buffer as hex`                                       |
| `dump()`                           | `Dumps the section / symbol / function / file under cursor in a new buffer`     |

--------------------------------------------------------------------------------

## Cookbook

**snacks.bigfile**

Snacks bigfile works by changing the filetype to `bigfile`. To override the
bigfile decision, add an `ftplugin/bigfile.lua` to your neovim config to
automatically `toggle_elf` when an ELF file is detected. This is a quick check,
as we only read the first 4 bytes of the file for `"\x7fELF"`.

```lua
-- ~/.config/nvim/ftplugin/bigfile.lua
if require("nvim-elf-file").is_elf_file() then
  require("nvim-elf-file").toggle_elf()
end
```

--------------------------------------------------------------------------------

[pi_zip]: https://neovim.io/doc/user/pi_zip.html
[plenary.nvim]: https://github.com/nvim-lua/plenary.nvim
[lazy.nvim]: https://github.com/folke/lazy.nvim
[packer]: https://github.com/wbthomason/packer.nvim
[mini.deps]: https://github.com/echasnovski/mini.deps
[Plug]: https://github.com/junegunn/vim-plug
