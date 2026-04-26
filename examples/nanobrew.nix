{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  # Internal configuration shortcut
  cfg = config.modules.darwin.nanobrew;
in
lib.mkModule {
  globalConfig = config;
  name = "darwin.nanobrew";
  description = "macOS nanobrew package manager setup";

  # Define the module options
  options = {
    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Homebrew formulae to install via nanobrew.";
    };
    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Homebrew casks to install via nanobrew.";
    };
    autoMigrate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to automatically migrate existing Homebrew installations.";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "gaurav";
      description = "The user who should own /opt/nanobrew.";
    };
  };

  # Implementation logic
  config = lib.mkIf cfg.enable {
    # 1. Import the base nix-nanobrew logic
    imports = [ inputs.nix-nanobrew.darwinModules.nix-nanobrew ];

    # 2. Map local options to the base module
    nix-nanobrew = {
      enable = true;
      user = cfg.user;
      autoMigrate = cfg.autoMigrate;
      brews = cfg.brews;
      casks = cfg.casks;
    };

    # 3. Extra system setup
    environment.systemPackages = with pkgs; [ pkg-config ];
    environment.systemPath = [ "/opt/nanobrew/prefix/bin" ];

    # 4. Handle Xcode/Rosetta prerequisites
    system.activationScripts.preActivation.text = ''
      echo "━━━ Checking Prerequisites ━━━"
      if ! xcode-select -p &> /dev/null; then
        echo "Installing Xcode Command Line Tools..."
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
        if [ -n "$PROD" ]; then
          softwareupdate -i "$PROD" --verbose
          echo "✓ Xcode Command Line Tools: Installed"
        fi
        rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      fi

      if ! /usr/bin/pgrep -q oahd; then
        echo "Installing Rosetta 2..."
        sudo softwareupdate --install-rosetta --agree-to-license 2>/dev/null || true
      fi
    '';
  };
}
