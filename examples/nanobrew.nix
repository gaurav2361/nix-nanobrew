# Genuine nanobrew configuration example
#
# This file demonstrates a clean, declarative setup for nanobrew.
# This config uses the 'nix-nanobrew' namespace directly.

{ config, lib, ... }:
let
  # Extract the primary user if on nix-darwin
  user = if config.system ? primaryUser then config.system.primaryUser else "yourname";
in
{
  nix-nanobrew = {
    enable = true;
    user = user;
    autoMigrate = true; # Reconcile existing packages

    onActivation = {
      cleanup = "uninstall"; # Genuine declarative cleanup: remove from config = remove from system
      upgrade = true;
    };

    # Declarative package lists
    brews = [
      "jq"
      "wget"
      "ffmpeg"
      "ripgrep"
      "netbirdio/tap/netbird"
      "Arthur-Ficial/tap/apfel"
    ];

    casks = [
      "iina"
      "raycast"
      "spotify"
      "obsidian"
      "visual-studio-code"
      "mhaeuser/mhaeuser/battery-toolkit"
    ];
  };
}
