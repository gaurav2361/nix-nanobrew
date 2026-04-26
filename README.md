# nix-nanobrew

`nix-nanobrew` manages [nanobrew](https://github.com/justrach/nanobrew) installations on macOS and Linux using Nix.
It provides genuine declarative management: removing a package from your config physically uninstalls it from the system.

## Why nix-nanobrew?

- **Fastest Homebrew Alternative:** nanobrew is written in Zig and is up to 140x faster than Homebrew on warm installs.
- **Genuine Declarative Management:** Unlike Homebrew which is often imperative, `nix-nanobrew` automatically uninstalls unlisted packages when `onActivation.cleanup = "uninstall"` is set.
- **Clean Configuration:** Matches the `nix-darwin` and `nix-homebrew` patterns exactly.

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
            user = "gaurav"; # The user owning the prefix
            
            onActivation = {
              cleanup = "uninstall"; # This ensures unlisted packages are removed
              upgrade = true;
            };

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
| `nix-nanobrew.onActivation.cleanup` | Set to `"uninstall"` for genuine declarative management. |
| `nix-nanobrew.onActivation.upgrade` | Upgrade all packages on each activation. |
| `nix-nanobrew.brews` | List of Homebrew formulae. |
| `nix-nanobrew.casks` | List of Homebrew casks (macOS only). |

## Modular Dotfiles Support

If you use a modular pattern like `modules.darwin.<name>.enable`, this module natively supports the `modules.darwin.nanobrew` namespace with the exact same options, so you don't need any boilerplate bridges.

## License

MIT
