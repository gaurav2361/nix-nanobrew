# nix-nanobrew

`nix-nanobrew` manages [nanobrew](https://github.com/justrach/nanobrew) installations on macOS and Linux using [nix-darwin](https://github.com/LnL7/nix-darwin) or NixOS.
It builds `nanobrew` from source and automatically initializes the `/opt/nanobrew` directory tree.

## Quick Start

Add the following to your Flake inputs:

```nix
{
  inputs = {
    nix-nanobrew.url = "github:justrach/nix-nanobrew";
    # (...)
  };
}
```

### Installation

```nix
{
  outputs = { self, nixpkgs, darwin, nix-nanobrew, ... }: {
    darwinConfigurations.macbook = {
      modules = [
        nix-nanobrew.darwinModules.nix-nanobrew
        {
          nix-nanobrew = {
            enable = true;
            user = "yourname";
            autoMigrate = true; # Automatically run 'nb migrate' if Homebrew is found
          };
        }
      ];
    };
  };
}
```

Once activated, the `nb` binary will be available in your PATH, and `/opt/nanobrew/prefix/bin` will be added to your shell's interactive initialization.

## Options

- `enable`: Whether to install and configure nanobrew.
- `user`: The user who should own `/opt/nanobrew`. Required.
- `group`: The group that should own `/opt/nanobrew`. Defaults to `admin`.
- `autoMigrate`: Whether to automatically migrate existing Homebrew installations.
- `enableBashIntegration`: Add `/opt/nanobrew/prefix/bin` to PATH in Bash.
- `enableZshIntegration`: Add `/opt/nanobrew/prefix/bin` to PATH in Zsh.
- `enableFishIntegration`: Add `/opt/nanobrew/prefix/bin` to PATH in Fish.

## Why nanobrew?

`nanobrew` is a fast, Zig-based alternative to Homebrew that uses Homebrew's bottles but provides a much faster and simpler experience. It's a single static binary and handles dependency resolution in parallel.
