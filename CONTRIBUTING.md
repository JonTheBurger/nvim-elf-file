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

This repo supplies dependencies via [nix flake]. To open an interactive nix
shell, run:

```bash
make shell
```

Once per-clone, you must use `luarocks` to install 3rd party dependencies to
`${PWD}/.luarocks`. The `make setup` command is provided to do so for
convenience:

```bash
make setup
```

> [!WARNING]
> Run `make clean` when switching between a `nix`-based `.luarocks` dir and a
> host-machine `.luarocks` dir.

Then use the `Makefile` to execute quality assurance commands:

```bash
$ make
Usage:
  make [<VARIABLE>=<value>] <goal>
Targets:
  help               Shows this message
  clean              Deletes artifacts
  distclean          Resets the repo back to its state at checkout
  shell              Enter a shell containing dev dependencies
  setup              Once-per-clone setup
  check              Runs quality assurance steps
  format             Reformats code
  lint               Runs static analysis tools
  test               Runs tests
  docs               Build the documentation
Variables:
  IN_NIX             [0] Set to 1 to run a command in the nix shell (make clean between nix and host shells)
```

> [!NOTE]
> All `Makefile` commands except `setup` and `shell` can use the nix shell by
> adding `IN_NIX=1` to the command line.

For convenience, `make check` runs `format`, `lint`, and `test`.

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
