# Only used for development & CI
{
  inputs = {
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs_25_11.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin_unstable.url = "github:nix-darwin/nix-darwin";
    nix-darwin_25_11.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";

    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs_unstable";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    # Keep zig-overlay for devShell if needed, but not for package build
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs_unstable";
    };
  };
  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs_unstable) lib;

      supportedSystems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      releases = {
        "unstable" = {
          nixpkgs = inputs.nixpkgs_unstable;
          nix-darwin = inputs.nix-darwin_unstable;
        };
        "25.11" = {
          nixpkgs = inputs.nixpkgs_25_11;
          nix-darwin = inputs.nix-darwin_25_11;
        };
      };

      githubPlatforms = {
        "aarch64-darwin" = "macos-26";
        "x86_64-darwin" = "macos-26";
        "x86_64-linux" = "ubuntu-latest";
        "aarch64-linux" = "ubuntu-latest";
      };

      matrix =
        let
          names = {
            release = builtins.attrNames releases;
            test = builtins.attrNames (
              import ./tests.nix {
                self = null;
                pkgs = null;
                nix-darwin = null;
              }
            );
          };
        in
        lib.pipe names [
          lib.cartesianProduct
          (map (setup: {
            name = "${setup.test}-${setup.release}";
            value = setup;
          }))
          lib.listToAttrs
        ];

      forAllSystems =
        f: lib.genAttrs supportedSystems (system: f inputs.nixpkgs_unstable.legacyPackages.${system});

      makeCi =
        { self, nanobrew-src }:
        let
          assembleTest =
            {
              system,
              release,
              test,
            }:
            let
              inputs' = releases.${release};
              pkgs = inputs'.nixpkgs.legacyPackages.${system};
              tests = import ./tests.nix {
                inherit self pkgs;
                inherit (inputs') nix-darwin;
              };
            in
            tests.${test};

          ciTests = lib.genAttrs supportedSystems (
            system:
            if lib.hasSuffix "-linux" system then
              { }
            # nix-darwin tests only run on darwin
            else
              lib.mapAttrs (
                name:
                { release, test }:
                assembleTest {
                  inherit system release test;
                }
              ) matrix
          );
          ciScripts = lib.mapAttrs (
            system: tests: lib.mapAttrs (name: test: test.config.system.build.ci-script) tests
          ) ciTests;
        in
        {
          inherit ciTests;
          packages = forAllSystems (
            pkgs:
            pkgs.callPackages (self + "/pkgs") {
              inherit nanobrew-src;
            }
          );
          devShell = forAllSystems (
            pkgs:
            pkgs.mkShell {
              nativeBuildInputs = with pkgs; [
                nixfmt-rfc-style
                inputs.zig-overlay.packages.${pkgs.system}."0.16.0"
              ];

              NANOBREW_SRC = nanobrew-src;
            }
          );
          githubActions = inputs.nix-github-actions.lib.mkGithubMatrix {
            checks = ciScripts;
            platforms = githubPlatforms;
          };
        };
    in
    {
      inherit makeCi;
    };
}
