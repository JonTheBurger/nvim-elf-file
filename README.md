# nvim-elf-file

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ellisonleao/nvim-plugin-template/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

--------------------------------------------------------------------------------

A simple plugin to browse `.elf` file contents in the style of [pi_zip].

Requires neovim 0.11+.

--------------------------------------------------------------------------------

## Installation

[lazy.nvim]

```lua
{
    "jontheburger/nvim-elf-file",
    opts = {},
}
```

[packer]:

```lua
{
    "jontheburger/nvim-elf-file", 
    opt = true,
    config = function()
        require("nvim-elf-file").setup({ })
    end
}
```

[mini.deps]:

```lua
add({
    source = 'jontheburger/nvim-elf-file',
    checkout = ''
})
```

[Plug]:

```lua
Plug("jontheburger/nvim-elf-file"[ do ] = function()
end)
```

--------------------------------------------------------------------------------

## Configuration

```lua
{
}
```

--------------------------------------------------------------------------------

[pi_zip]: https://neovim.io/doc/user/pi_zip.html
[lazy.nvim]: https://github.com/folke/lazy.nvim
[packer]: https://github.com/wbthomason/packer.nvim
[mini.deps]: https://github.com/echasnovski/mini.deps
[Plug]: https://github.com/junegunn/vim-plug
