{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

      in
      {
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              coreutils
              curl
              findutils
              gawk
              gcc
              pkg-config
              glibc
              git
              gnumake
              lua5_1
              luarocks
              neovim
              panvimdoc
            ];
            # This fixes luasystem  not being able to find RT_DIR upon install
            shellHook = ''
              luarocks() { command luarocks "$@" RT_DIR="${pkgs.glibc.out}"; }
              export -f luarocks
            '';
          };
        };
      }
    );
}
