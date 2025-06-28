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
            luarocks --tree .luarocks install llscheck 0.7.0-1
            luarocks --tree .luarocks install luacheck 1.2.0-1
            luarocks --tree .luarocks install luacov 0.16.0-1
            export PATH="$PWD/.luarocks/bin:$PATH"
          '';
        };
      });
}
