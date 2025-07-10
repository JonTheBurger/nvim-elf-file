# Contributing

The principle aim of `nvim-elf-file` is to automate the tedious part of using
readelf/objdump.

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

Once per-clone, you must use `make setup` to install 3rd party `luarocks` CI
dependencies to `${PWD}/.luarocks`:

```bash
make setup
```

> [!WARNING]
> Run `make clean setup` whenever you witch between your host environment, nix
> develop shell, and docker container.

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
  cov                Generates test coverage
  docs               Build the documentation
  docker.build       Builds the docker image
  docker.run         Runs the docker image
Variables:
  IN_NIX             [0] Set to 1 to run a command in the nix shell
  IN_DOCKER          [0] Set to 1 to run a command in a docker container
```

> [!NOTE]
> All `Makefile` commands except `setup`, `shell`, and `docker.*` can use the
> nix shell or docker container by adding `IN_NIX=1` or `IN_DOCKER=1` to the
> command line respectively.

For convenience, `make check` runs `format`, `lint`, `test`, and cov.

For the best experience, use `make shell` and `make setup` when developing
locally. Use `make docker.run` to diagnose environment leaks.

## Notes

- `init.lua` is intended to be API stable - don't break users!
- `CHANGELOG.md` should be updated for each release.
- Docs are generated locally - if you update config, please update the
  `README.md` and run `make docs`.
- Use `require("nvim-elf-file.elf").readelf()` instead of
  `require("nvim-elf-file.config").options.readelf()`.

## Roadmap

- bin file search
- snacks picker strings in bin
- bin goto byte
- snacks picker symbols / sections in elf
- `vim.ui.input({prompt="Search Text: "}, function(s) end)` if s ~= ""
    - `:lua vim.fn.search([[00\(  .\+\_s\d\+: \)\?03]])`
    - `:lua vim.fn.search([[A\(\_s.*  \)\?B]])`
- `rg ABSL options-pinned.h -b -N -o -m 1 -U --binary --byte-ffset 0`
- `local pos = vim.fn.getpos(".")  -- {bufnum, line, col, off}`
- `local byte_offset = vim.fn.line2byte(pos[2]) + pos[3] - 2`
- set cursor position as byte index when toggling binary
- Hover hints: vim.lsp.util.open_floating_preview(), vim.api.nvim_open_with()
- cache readelf/objdump per-buffer
- `nvim_buf_add_highlight`
- gifs in docs

--------------------------------------------------------------------------------

[Best Practices]: https://github.com/nvim-neorocks/nvim-best-practices
[nix flake]: https://wiki.nixos.org/wiki/Flakes
