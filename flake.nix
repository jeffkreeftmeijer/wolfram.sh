{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        devShell = with pkgs;
          mkShell {
            packages = [
              (bats.withLibraries (batsPackages: [
                batsPackages.bats-support
                batsPackages.bats-assert
              ]))
            ];
          };
      }
    );
}
