# Contributing

The principle aims of `nvim-elf-file` are to:

1. Learn the complete set of basics for creating neovim plugins.
2. Automate the tedious part of using readelf/objdump.
3. Extract `toggle_bin` from my dotfiles to a standalone plugin.

The repo makes extensive use of typing and comments, plus static analysis to
aid in understanding the code base. Furthermore, the neorocks [Best Practices]
document has been (mostly) followed. Please keep with this style as you
develop.

## Setup

This repo supplies dependencies via [nix flake]. To open a nix shell, run:

```bash
nix develop
```

Then use the `Makefile` to execute quality assurance commands:

```bash
$ make
Usage:
  make [<VARIABLE>=<value>] <goal>
Targets:
  help               Shows this message
  clean              Deletes the build dir
  distclean          Resets the repo back to its state at checkout
  docs               Build the documentation
  check              Runs quality assurance steps
  format             Reformats code
  lint               Runs static analysis tools
  test               Runs tests
  cov                Generates test coverage
Variables:
```

For convenience, `make check` runs `format`, `lint`, `test`, and `cov`.

## Notes

- `init.lua` is intended to be API stable - don't break users!
- `CHANGELOG.md` should be updated for each release.
- Docs are generated locally - if you update config, please update the
  `README.md` and run `make docs`.
- Use `require("nvim-elf-file.elf").readelf()` instead of
  `require("nvim-elf-file.config").options.readelf()`.

## Roadmap

- ci
- gifs in docs
- Hover hints: vim.lsp.util.open_floating_preview(), vim.api.nvim_open_with()
- cache readelf/objdump per-buffer
- set cursor position as byte index when toggling binary
- bin file search

--------------------------------------------------------------------------------

[Best Practices]: https://github.com/nvim-neorocks/nvim-best-practices
[nix flake]: https://wiki.nixos.org/wiki/Flakes
