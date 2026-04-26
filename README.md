# nix-nanobrew

`nix-nanobrew` manages [nanobrew](https://github.com/justrach/nanobrew) installations on macOS and Linux using Nix.
It pins the nanobrew version, manages the `/opt/nanobrew` prefix, and provides declarative package management.

## Why nix-nanobrew?

- **Fastest Homebrew Alternative:** nanobrew is written in Zig and is up to 140x faster than Homebrew on warm installs.
- **Genuine Declarative Management:** Unlike Homebrew which is often imperative, `nix-nanobrew` can automatically uninstall unlisted packages when `onActivation.cleanup = "uninstall"` is set.
- **Zero Subprocess Overhead:** No Ruby runtime, no configuration sprawl. Just one static binary.

## Quick Start

### 1. Add to your Flake inputs

```nix
{
  inputs = {
    nix-nanobrew.url = "github:gaurav2361/nix-nanobrew";
    # ...
  };
}
```

### 2. Configure the Module

```nix
{
  outputs = { self, nix-nanobrew, ... }: {
    darwinConfigurations.macbook = {
      modules = [
        nix-nanobrew.darwinModules.nix-nanobrew
        {
          nix-nanobrew = {
            enable = true;
            user = "yourname"; # The user owning the prefix
            
            # Optional: Declarative cleanup
            onActivation.cleanup = "uninstall";

            # Declarative packages
            brews = [ "jq" "wget" ];
            casks = [ "raycast" "spotify" ];
          };
        }
      ];
    };
  };
}
```

## Options

| Option | Description |
|--------|-------------|
| `nix-nanobrew.enable` | Whether to install nanobrew. |
| `nix-nanobrew.user` | The user who should own `/opt/nanobrew`. |
| `nix-nanobrew.autoMigrate` | Automatically import existing Homebrew packages on first run. |
| `nix-nanobrew.brews` | List of Homebrew formulae to manage. |
| `nix-nanobrew.casks` | List of Homebrew casks to manage (macOS only). |
| `nix-nanobrew.onActivation.cleanup` | Set to `"uninstall"` to remove packages not in the config. |
| `nix-nanobrew.onActivation.upgrade` | Upgrade all packages on each activation. |

## Modular Dotfiles Style

If you use a modular pattern like `lib.mkModule`, forward your custom options to `nix-nanobrew`:

```nix
config = lib.mkIf config.modules.darwin.nanobrew.enable {
  nix-nanobrew = {
    enable = true;
    user = "gaurav";
    autoMigrate = true;
    # ...
  };
};
```

## License

MIT
