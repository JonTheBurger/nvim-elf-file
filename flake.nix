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
              git
              glibc
              gnumake
              lua-language-server
              lua5_1
              luarocks
              neovim
              panvimdoc
              pkg-config
              ripgrep
              stylua
              xxd
            ];
            shellHook = ''
              export RT_DIR="${pkgs.glibc.out}"
            '';
          };
        };
      }
    );
}
