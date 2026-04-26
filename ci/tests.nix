{
  self,
  pkgs,
  nix-darwin,
}:

let
  inherit (pkgs) lib system;

  tools = self.packages.${pkgs.system};

  makeTest =
    module:
    nix-darwin.lib.darwinSystem {
      inherit system pkgs;
      modules = [
        self.darwinModules.nix-nanobrew
        module
        (
          {
            pkgs,
            lib,
            config,
            ...
          }:
          {
            options = {
              ci = {
                preScript = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                };
                script = lib.mkOption {
                  type = lib.types.lines;
                  default = ''
                    sudo rm -f /etc/bashrc /etc/nix/nix.conf /etc/nix/nix.custom.conf
                    sudo "${config.system.build.toplevel}/activate"
                    export PATH=/run/current-system/sw/bin:$PATH
                  '';
                };
                postScript = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                };
              };
            };
            config = {
              documentation.enable = false;
              system.stateVersion = 6;
              nix-nanobrew = {
                user = lib.mkForce "runner";
              };

              system.build.ci-script = pkgs.writeShellScript "ci-script.sh" ''
                set -euo pipefail
                if [[ -z "''${NIX_NANOBREW_CI:-}" ]]; then
                  >&2 echo "This script can only be run on nix-nanobrew CI."
                  exit 1
                fi
                set -x
                ${config.ci.preScript}
                ${config.ci.script}
                ${config.ci.postScript}
              '';
            };
          }
        )
      ];
    };
in
{
  migrate = makeTest (
    { pkgs, config, ... }:
    {
      imports = [
        (self + "/examples/migrate.nix")
      ];

      ci.preScript = lib.optionalString pkgs.stdenv.hostPlatform.isAarch64 ''
        >&2 echo "Creating dummy /opt/homebrew to test migration"
        sudo mkdir -p /opt/homebrew/Cellar
      '';
      ci.postScript = ''
        >&2 echo "Checking nb"
        which nb
        nb help
      '';
    }
  );
}
