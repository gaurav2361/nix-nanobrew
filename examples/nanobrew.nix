# Genuine nanobrew configuration for modular dotfiles
#
# This file is intended to be used in a nix-darwin setup (e.g., as modules/darwin/nanobrew.nix)
# It bridges your custom 'modules.darwin.nanobrew' namespace to 'nix-nanobrew'.

{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.darwin.nanobrew;
  # Fallback to primaryUser if on nix-darwin, otherwise generic
  defaultUser = if config.system ? primaryUser then config.system.primaryUser else "yourname";
in
{
  options.modules.darwin.nanobrew = {
    enable = lib.mkEnableOption "macOS nanobrew package manager setup";
    user = lib.mkOption {
      type = lib.types.str;
      default = defaultUser;
      description = "User owning the /opt/nanobrew directory";
    };
    autoMigrate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically migrate from existing Homebrew";
    };
    cleanup = lib.mkOption {
      type = lib.types.enum [
        "none"
        "uninstall"
      ];
      default = "uninstall";
      description = "Whether to uninstall unlisted packages";
    };
  };

  config = lib.mkIf cfg.enable {
    # Forward to the genuine nix-nanobrew module
    nix-nanobrew = {
      enable = true;
      user = cfg.user;
      autoMigrate = cfg.autoMigrate;
      onActivation.cleanup = cfg.cleanup;
      onActivation.upgrade = true;

      # Package lists
      brews = [
        "jq"
        "wget"
        "ffmpeg"
        "ripgrep"
      ];

      casks = [
        "iina"
        "raycast"
        "spotify"
        "obsidian"
        "visual-studio-code"
      ];
    };
  };
}
