# nixos-update-notify

A simple NixOS module that checks for channel updates and shows a desktop notification when updates are available.

## Features

- Checks the NixOS Prometheus API for the latest channel revision
- Compares against your running system's revision
- Shows a persistent critical notification when updates are available
- Configurable channel and check time
- Runs as a systemd user timer

## Installation

### Option 1: Local Installation (Simple)

Copy the module to a root-owned location:

```bash
sudo mkdir -p /etc/nixos/modules
sudo cp /path/to/nixos-update-notify/module.nix /etc/nixos/modules/nixos-update-notify.nix
sudo chown root:root /etc/nixos/modules/nixos-update-notify.nix
```

Then add to your `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./modules/nixos-update-notify.nix
  ];

  services.nixos-update-notify = {
    enable = true;
    channel = "nixos-unstable";
  };
}
```

### Option 2: Fetch from Git (Pinned)

Fetch directly from a git repository with a pinned commit:

```nix
{ config, pkgs, ... }:
{
  imports = [
    "${builtins.fetchGit {
      url = "https://github.com/erichelgeson/nixos-update-notify.git";
      rev = "0357ccc2a344e9f14f27fcc1fdb35df8b930c02b";  # Pin to specific commit for security
    }}/module.nix"
  ];

  services.nixos-update-notify = {
    enable = true;
    channel = "nixos-unstable";
  };
}
```

### Option 3: Using Flakes

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

Then rebuild:

```bash
sudo nixos-rebuild switch
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the update notifier |
| `channel` | string | `"nixos-unstable"` | NixOS channel to monitor |
| `startHour` | int | `7` | Hour to start checking (0-23) |
| `endHour` | int | `22` | Hour to stop checking (0-23) |
| `minute` | int | `30` | Minute of each hour to check (0-59) |

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

## KDE Discover Backend (Experimental)

This project also includes an experimental KDE Discover backend that shows NixOS updates directly in the Discover application.

### Installation

Using flakes, add the discover-backend module:

```nix
{
  inputs.nixos-update-notify.url = "github:YOURUSER/nixos-update-notify";

  outputs = { nixpkgs, nixos-update-notify, ... }: {
    nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
      modules = [
        nixos-update-notify.nixosModules.discover-backend
        ./configuration.nix
      ];
    };
  };
}
```

Then enable it:

```nix
{
  services.nixos-discover-backend = {
    enable = true;
    channel = "nixos-unstable";
  };
}
```

### How it Works

The backend queries the same Prometheus API and displays a "NixOS System" update in Discover when your system revision differs from the channel. It does not perform the update itself - you still need to run `sudo nixos-rebuild switch` manually.

### Development

Enter the development shell:

```bash
nix develop  # or: nix-shell
```

Build the backend:

```bash
cmake -B build -G Ninja
cmake --build build
```

Test with Discover:

```bash
QT_PLUGIN_PATH=$PWD/build plasma-discover
```
