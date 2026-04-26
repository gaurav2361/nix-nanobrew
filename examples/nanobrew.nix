# Genuine nanobrew configuration example
#
# This file demonstrates how to use the nix-nanobrew module
# in a standard Nix configuration.

{ pkgs, inputs, ... }:
{
  # 1. Import the nix-nanobrew module from flake inputs
  imports = [ inputs.nix-nanobrew.darwinModules.nix-nanobrew ];

  # 2. Configure nix-nanobrew options directly
  nix-nanobrew = {
    enable = true;
    user = "yourname"; # Replace with your actual username
    autoMigrate = true; # Set to true to import existing Homebrew packages

    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = true;
    };

    # Declarative package lists
    brews = [
      "mas"
      "mole"
      "sheets"
      "libiconv"
      "tesseract"
      "gemini-cli"
      "tree-sitter"
      "tesseract-lang"
      "tree-sitter-cli"
      "netbirdio/tap/netbird"
      "Arthur-Ficial/tap/apfel"
    ];

    casks = [
      "iina"
      "blip"
      "bruno"
      "motrix"
      "raycast"
      "spotify"
      "obsidian"
      "antigravity"
      "google-drive"
      "google-chrome"
      "brave-browser"
      "keyboardcleantool"
      "mhaeuser/mhaeuser/battery-toolkit"
    ];
  };

  # 3. Extra system setup (optional)
  environment.systemPackages = with pkgs; [ pkg-config ];
  environment.systemPath = [ "/opt/nanobrew/prefix/bin" ];

  # 4. Handle Xcode prerequisites (standard pattern)
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
}
