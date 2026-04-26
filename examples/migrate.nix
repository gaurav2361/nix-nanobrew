# Migrate from an existing Homebrew installation

{ pkgs, ... }:
{
  nix-nanobrew = {
    enable = true;
    autoMigrate = true;
    user = "yourname";
  };
}
