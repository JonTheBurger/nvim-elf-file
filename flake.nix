# nix develop
{
  description = "Dev environment for nvim-elf-file";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        luaPackages = pkgs.luaPackages;

      in {
        devShell = pkgs.mkShell {
          name = "nvim-elf-file-dev";
          packages = with pkgs; [
            coreutils
            curl
            findutils
            gawk
            git
            gnumake
            luarocks
            neovim
            panvimdoc
            stylua
          ];

          shellHook = ''
            make setup
          '';
        };
      });
}
