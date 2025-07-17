# nvim-elf-file

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?logo=lua)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jontheburger/nvim-elf-file/ci.yml?branch=main)

--------------------------------------------------------------------------------

A simple plugin to browse `.elf` and `bin` file contents in the style of
[pi_zip](https://neovim.io/doc/user/pi_zip.html).

--------------------------------------------------------------------------------

## Features

![elf file support](doc/elf.gif)

- Disassemble functions
- Dump section / object contents

![binary file support](doc/bin.gif)

- Show address cursor hover
- Jump to address
- Search hex/text
- Browse strings
- Fit/refresh contents to window width

> [!TIP]
> Use `?` in an elf/bin file to see the key bindings.

--------------------------------------------------------------------------------

## Installation

Requires:

- neovim `0.11.0`+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "jontheburger/nvim-elf-file",
  dependencies = { "nvim-lua/plenary.nvim" },
  ---@type nvim-elf-file.UserOptions
  opts = {},
  keys = {
    { "<leader>x", "<Plug>(nvim-elf-file-toggle-bin)", desc = "Toggle Bin View" },
  },
  cmd = { "ElfFile" },
}
```

[packer](https://github.com/wbthomason/packer.nvim):

```lua
{
  "jontheburger/nvim-elf-file", 
  requires = { "nvim-lua/plenary.nvim" },
  opt = true,
  config = function()
    require("nvim-elf-file").setup({})
    vim.keymap.set("n", "<leader>x", "<Plug>(nvim-elf-file-toggle-bin)", { noremap = true, desc = "Toggle Bin View", })
  end
}
```

[mini.deps](https://github.com/echasnovski/mini.deps):

```lua
local add = MiniDeps.add
add({
  source = "jontheburger/nvim-elf-file",
  depends = { "nvim-lua/plenary.nvim" },
  checkout = ""
})
```

--------------------------------------------------------------------------------

## Dependencies

This plugin uses some external programs to run properly. Please ensure the
following are installed:

- `readelf` (and any architecture-specific `readelf`, such as `arm-none-eabi-readelf`)
- `objdump` (and any architecture-specific `objdump`, such as `arm-none-eabi-objdump`)
- `xxd`
- `strings`
- `rg` (ripgrep)

--------------------------------------------------------------------------------

## Configuration

The following the default `opts`:

```lua
---@type nvim-elf-file.UserOptions
opts = {
  -- Path to single readelf program name / executable path,
  -- readelf = "/usr/bin/readelf",

  -- Or a function that picks readelf based on machine (see table below)
  -- nil should return a default implementation
  ---@param machine? string
  readelf = function(machine)
    if machine == "ARM" then
      return "arm-none-eabi-readelf"
    end
    return "readelf"
  end,

  -- Same thing as readelf, but for objdump
  ---@param machine? string
  objdump = function(machine)
    if machine == "ARM" then
      return "arm-none-eabi-objdump"
    end
    return "objdump"
  end,

  -- Name of strings command
  strings = "strings",

  -- Name of ripgrep command
  rg = "rg",

  -- Name of binary dumping program (not machine-dependent)
  xxd = {
    -- Name of or path to xxd executable
    executable = "xxd",
    -- Number of bytes to group in a column (2 nibbles per-byte)
    bytes_per_column = 2,
    -- Number of bytes to group in a line ("auto" to fill the line)
    bytes_per_line = "auto",
    -- How to display the address ("hexadecimal" or "decimal")
    address_format = "hexadecimal",
    -- Replace consecutive lines of all '0' with a '*'
    skip_zeros = false,
    -- Use uppercase letters for hexadecimal
    uppercase = false,
  },

  -- nvim-elf-file buffer-specific keymaps.
  -- Each entry is a <Plug>(nvim-elf-file-<command>)
  -- See list of commands in "Usage" below
  keymaps = {
    ["?"] = "help",
    ["<CR>"] = "dump",
    ["<S-K>"] = "hover",
    ["sj"] = "jump",
    ["sb"] = "search-bin",
    ["st"] = "search-text",
    ["ss"] = "search-strings",
    ["<F1>"] = "hover",
    ["<F4>"] = "jump",
    ["<F5>"] = "refresh",
    ["<F12>"] = "dump",
  },

  -- Set to false to disable automatic conversion of the filetype's buffer
  automatic = {
    elf = true,
    bin = true,
    -- Automatically refresh the render when window size changes
    refresh = false,
  },

  -- List of registers to yank strings to
  yank_registers = { "0", "'", '"' },

  -- What to do when a e.g. disassembled function buffer goes out of view.
  -- By default, it is wiped out.
  bufhidden = "wipe",

  -- Verbosity of `vim.fn.stdpath("data") .. "/nvim-elf-file.log"`
  log_level = "info",
}
```

Some common machines include:

| Machine (from `readelf`)        | Architecture        |
| ------------------------------- | ------------------- |
| `Advanced Micro Devices X86-64` | 64-bit x86 (x86_64) |
| `Intel 80386`                   | 32-bit x86          |
| `ARM`                           | 32-bit ARM          |
| `AArch64`                       | 64-bit ARM          |
| `MIPS R3000`                    | MIPS                |
| `RISC-V`                        | RISC-V              |
| `PowerPC`                       | PowerPC             |
| `SPARC`                         | SPARC               |

> [!TIP]
> You can set `vim.g.loaded_nvim_elf_file = true` to turn off the plugin entirely.

--------------------------------------------------------------------------------

## Usage

This plugin provides the `ElfFile` EX Command with sub-commands:

| Command                  | Description                                      |
| ------------------------ | ------------------------------------------------ |
| `ElfFile help`           | `Show keybinds`                                  |
| `ElfFile toggle`         | `Toggle display based on filetype`               |
| `ElfFile toggle elf`     | `Toggle readelf display`                         |
| `ElfFile toggle bin`     | `Toggle xxd binary display`                      |
| `ElfFile dump`           | `Dump section/symbol/file under cursor`          |
| `ElfFile jump`           | `Jump toan address in a binary file`             |
| `ElfFile hover`          | `Show a hover with additional info`              |
| `ElfFile search bin`     | `Search for raw bytes in a binary file`          |
| `ElfFile search text`    | `Search for textin a binary file`                |
| `ElfFile search strings` | `Yank from the strings present in a binary file` |
| `ElfFile refresh`        | `Reload toggle`                                  |

This plugin also provides `<Plug>(nvim-elf-file-<command>)` mappings:

| Mapping                                | Command                  |
| -----------------------------------    | ------------------------ |
| `<Plug>(nvim-elf-file-help)`           | `ElfFile help`           |
| `<Plug>(nvim-elf-file-toggle)`         | `ElfFile toggle`         |
| `<Plug>(nvim-elf-file-toggle-elf)`     | `ElfFile toggle elf`     |
| `<Plug>(nvim-elf-file-toggle-bin)`     | `ElfFile toggle bin`     |
| `<Plug>(nvim-elf-file-dump)`           | `ElfFile dump`           |
| `<Plug>(nvim-elf-file-jump)`           | `ElfFile jump`           |
| `<Plug>(nvim-elf-file-hover)`          | `ElfFile hover`          |
| `<Plug>(nvim-elf-file-search-bin)`     | `ElfFile search bin`     |
| `<Plug>(nvim-elf-file-search-text)`    | `ElfFile search text`    |
| `<Plug>(nvim-elf-file-search-strings)` | `ElfFile search strings` |
| `<Plug>(nvim-elf-file-refresh)`        | `ElfFile refresh`        |

This plugin also keeps the lua API located in `require("nvim-elf-file")` stable:

| Function            | Command                                                                         |
| ------------------- | ------------------------------------------------------------------------------- |
| `setup(opts)`       | `Set up the plugin with custom settings`                                        |
| `is_elf_file(file)` | `Checks if thebufnr/string path is an ELF file by checking for the magic bytes` |
| `help()`            | `Show keybinds`                                                                 |
| `toggle()`          | `Toggle based on file type`                                                     |
| `toggle_elf()`      | `Uses readelf to dump the elf file contents into a readonly buffer`             |
| `toggle_bin()`      | `Uses xxd dump the current buffer as hex`                                       |
| `dump()`            | `Dumps the section / symbol / function / file under cursor in a new buffer`     |
| `jump()`            | `Jump to an address in a bin file`                                              |
| `hover()`           | `Show additional information about the item under the cursor`                   |
| `search_binary()`   | `Search for raw bytes in a bin file using rg`                                   |
| `search_text()`     | `Search for text in a bin file using rg`                                        |
| `search_strings()`  | `Select from text in a bin file using strings`                                  |
| `refresh()`         | `Redo toggle`                                                                   |

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
