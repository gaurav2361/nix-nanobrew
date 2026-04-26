{
  description = "nanobrew installation manager for nix-darwin";

  inputs = {
    nanobrew-src = {
      url = "github:justrach/nanobrew";
      flake = false;
    };
  };

  outputs =
    { self, nanobrew-src }:
    let
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

      packages = {
        x86_64-darwin.nanobrew = ci.packages.x86_64-darwin.nanobrew;
        aarch64-darwin.nanobrew = ci.packages.aarch64-darwin.nanobrew;
        x86_64-linux.nanobrew = ci.packages.x86_64-linux.nanobrew;
        aarch64-linux.nanobrew = ci.packages.aarch64-linux.nanobrew;
      };

      inherit (ci) devShell ciTests githubActions;
    };
}
