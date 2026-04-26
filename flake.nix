{
  description = "nanobrew installation manager for nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nanobrew-src = {
      url = "github:justrach/nanobrew";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nanobrew-src,
    }:
    let
      supportedSystems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      ci = (import ./ci/flake-compat.nix).makeCi {
        inherit self nanobrew-src;
      };
    in
    {
      darwinModules = rec {
        nix-nanobrew =
          { pkgs, lib, ... }:
          {
            imports = [
              ./modules
            ];
            nix-nanobrew.package = lib.mkOptionDefault (self.packages.${pkgs.system}.nanobrew);
          };

        default = nix-nanobrew;
      };

      packages = forAllSystems (system: {
        nanobrew = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/nanobrew { };
        default = self.packages.${system}.nanobrew;
      });

      inherit (ci) devShell ciTests githubActions;
    };
}
