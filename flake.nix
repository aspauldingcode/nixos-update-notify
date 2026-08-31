{
  description = "NixOS / nix-darwin update notifier - desktop notification when channel updates are available";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
  let
    linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
    forLinuxSystems = nixpkgs.lib.genAttrs linuxSystems;
  in {
    nixosModules.default = import ./module.nix;
    nixosModules.nixos-update-notify = import ./module.nix;

    darwinModules.default = import ./module.nix;
    darwinModules.nixos-update-notify = import ./module.nix;

    # KDE Discover backend module (Linux only)
    nixosModules.discover-backend = { config, lib, pkgs, ... }: {
      options.services.nixos-discover-backend = {
        enable = lib.mkEnableOption "NixOS Discover backend";

        channel = lib.mkOption {
          type = lib.types.str;
          default = "nixos-unstable";
          description = "NixOS channel to monitor for updates.";
        };
      };

      config = lib.mkIf config.services.nixos-discover-backend.enable {
        environment.systemPackages = [
          self.packages.${pkgs.system}.discover-backend
        ];
        environment.sessionVariables.QT_PLUGIN_PATH = [
          "${self.packages.${pkgs.system}.discover-backend}/lib/qt-6/plugins"
        ];
      };
    };

    packages = forLinuxSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        discover-backend = pkgs.callPackage ./default.nix {};
        default = self.packages.${system}.discover-backend;
      }
    );

    devShells = forLinuxSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = import ./shell.nix { inherit pkgs; };
      }
    );
  };
}
