# nixos-update-notify

A simple NixOS module that checks for channel updates and shows a desktop notification when updates are available.

## Features

- Checks the NixOS Prometheus API for the latest channel revision
- Compares against your running system's revision
- Shows a persistent critical notification when updates are available
- Configurable channel and check time
- Runs as a systemd user timer

## Installation

Add to your `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:
{
  imports = [
    /path/to/nixos-update-notify/module.nix
  ];

  services.nixos-update-notify = {
    enable = true;
    channel = "nixos-unstable";  # Channel to monitor
    time = "07:30";              # Time to check (HH:MM)
  };
}
```

Then rebuild:

```bash
sudo nixos-rebuild switch
```

### Using Flakes

If you use flakes, add to your `flake.nix`:

```nix
{
  inputs.nixos-update-notify.url = "github:YOURUSER/nixos-update-notify";

  outputs = { nixpkgs, nixos-update-notify, ... }: {
    nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
      modules = [
        nixos-update-notify.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the update notifier |
| `channel` | string | `"nixos-unstable"` | NixOS channel to monitor |
| `time` | string | `"07:30"` | Time to check for updates (HH:MM) |

### Available Channels

- `nixos-unstable`
- `nixos-unstable-small`
- `nixos-25.11`
- `nixos-25.11-small`
- `nixpkgs-unstable`

## Testing

Manually trigger a check:

```bash
systemctl --user start nixos-update-notify.service
```

Check timer status:

```bash
systemctl --user status nixos-update-notify.timer
```

View logs:

```bash
journalctl --user -u nixos-update-notify.service
```
