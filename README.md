# nix-nanobrew

`nix-nanobrew` manages [nanobrew](https://github.com/justrach/nanobrew) installations on macOS and Linux using [nix-darwin](https://github.com/LnL7/nix-darwin) or NixOS.
It builds `nanobrew` from source and optionally allows for declarative specification of brews and casks.

`nix-nanobrew` installs the `nb` binary and manages the `/opt/nanobrew` prefix. It also provides a compatibility `brew` launcher that redirects to `nb`, allowing you to use existing Homebrew declarative configurations seamlessly.

## Quick Start

First of all, you must have [nix-darwin](https://github.com/LnL7/nix-darwin) (or NixOS) configured already.
Add the following to your Flake inputs:

```nix
{
  inputs = {
    nix-nanobrew.url = "github:gaurav2361/nix-nanobrew";
    # (...)
  };
}
```

### A. New Installation

If you haven't installed nanobrew before, use the following configuration:

```nix
{
  output = { self, nixpkgs, darwin, nix-nanobrew, ... }: {
    darwinConfigurations.macbook = {
      # (...)
      modules = [
        nix-nanobrew.darwinModules.nix-nanobrew
        {
          nix-nanobrew = {
            # Install nanobrew and initialize /opt/nanobrew
            enable = true;

            # User owning the nanobrew prefix
            user = "yourname";

            # Optional: Declarative package management
            brews = [
              "jq"
              "wget"
              "netbirdio/tap/netbird" # Taps work natively without a separate 'taps' option
            ];
            casks = [
              "raycast"
              "spotify"
            ];
          };
        }
      ];
    };
  };
}
```

Once activated, the `nb` binary and a compatibility `brew` launcher will be created. `/opt/nanobrew/prefix/bin` will be automatically added to your shell's PATH.

### B. Existing Homebrew Installation

If you've already installed Homebrew with the official script, you can let `nix-nanobrew` automatically migrate your packages:

```nix
{
  output = { self, darwin, nix-nanobrew, ... }: {
    darwinConfigurations.macbook = {
      # (...)
      modules = [
        nix-nanobrew.darwinModules.nix-nanobrew
        {
          nix-nanobrew = {
            enable = true;
            user = "yourname";

            # Automatically run 'nb migrate' to import packages from Homebrew
            autoMigrate = true;
          };
        }
      ];
    };
  };
}
```

## Declarative Packages

`nanobrew` is "tap-less" by design. It fetches Ruby formulas directly from GitHub on-the-fly. This means you don't need a separate `taps` attribute; simply use the full name (e.g., `user/tap/formula`) in your `brews` or `casks` list.

### Compatibility with `homebrew.*` options

`nix-nanobrew` provides a unified `brew` launcher that intercepts calls to `brew bundle`. This means your existing `nix-darwin` Homebrew configuration will often work without changes:

```nix
{
  nix-nanobrew = {
    enable = true;
    user = "gaurav";
  };

  # This standard nix-darwin block will now be handled by nanobrew!
  homebrew = {
    enable = true;
    brews = [ "ripgrep" ];
    casks = [ "firefox" ];
  };
}
```

## Options

- `enable`: Whether to install and configure nanobrew.
- `user`: The user who should own `/opt/nanobrew`. **Required**.
- `group`: The group that should own `/opt/nanobrew`. Defaults to `admin`.
- `autoMigrate`: Whether to automatically migrate existing Homebrew installations.
- `brews`: List of formulae to install declaratively.
- `casks`: List of casks to install declaratively.
- `enableBashIntegration`: Add `/opt/nanobrew/prefix/bin` to PATH in Bash.
- `enableZshIntegration`: Add `/opt/nanobrew/prefix/bin` to PATH in Zsh.
- `enableFishIntegration`: Add `/opt/nanobrew/prefix/bin` to PATH in Fish.

## Why nanobrew?

`nanobrew` is a fast, Zig-based alternative to Homebrew.
- **Speed**: Warm installs in ~3.5ms, parallel everything.
- **Simplicity**: Single static binary, no Ruby runtime required.
- **Modern**: Uses APFS clonefile for zero-copy materialization.
- **Cross-Platform**: Works natively on both macOS and Linux.
