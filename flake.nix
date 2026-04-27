{
  description = "nanobrew installation manager for nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nanobrew-src = {
      url = "github:justrach/nanobrew";
      flake = false;
    };
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nanobrew-src,
      zig-overlay,
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

      nix-nanobrew-module =
        { pkgs, lib, ... }:
        {
          imports = [
            ./modules
          ];
          nix-nanobrew.package = lib.mkOptionDefault (self.packages.${pkgs.system}.nanobrew);
        };
    in
    {
      darwinModules = {
        nix-nanobrew = nix-nanobrew-module;
        default = nix-nanobrew-module;
      };

      nixosModules = {
        nix-nanobrew = nix-nanobrew-module;
        default = nix-nanobrew-module;
      };

      packages = forAllSystems (system: {
        nanobrew = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/nanobrew {
          inherit nanobrew-src;
          zig = zig-overlay.packages.${system}."0.16.0";
        };
        default = self.packages.${system}.nanobrew;
      });

      inherit (ci) devShell ciTests githubActions;
    };
}
