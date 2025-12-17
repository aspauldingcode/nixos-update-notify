{
  description = "NixOS update notifier - shows a notification when channel updates are available";

  outputs = { self, ... }: {
    nixosModules.default = import ./module.nix;
    nixosModules.nixos-update-notify = import ./module.nix;
  };
}
