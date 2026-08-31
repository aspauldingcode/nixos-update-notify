{ config, lib, pkgs, ... }:

let
  cfg = config.services.nixos-update-notify;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  checkUpdateScript = pkgs.writeShellApplication {
    name = "nixos-update-notify";
    runtimeInputs =
      with pkgs;
      [
        curl
        jq
      ]
      ++ lib.optionals isLinux [ libnotify ]
      ++ lib.optionals isDarwin [ terminal-notifier ];
    text = ''
      CHANNEL="${cfg.channel}"
      ${builtins.readFile ./check-update.sh}
    '';
  };

  calendarHours = lib.range cfg.startHour cfg.endHour;
in
{
  options.services.nixos-update-notify = {
    enable = lib.mkEnableOption "NixOS / nix-darwin update notifier";

    channel = lib.mkOption {
      type = lib.types.str;
      default = if isDarwin then "nixpkgs-unstable" else "nixos-unstable";
      defaultText = lib.literalExpression ''if pkgs.stdenv.hostPlatform.isDarwin then "nixpkgs-unstable" else "nixos-unstable"'';
      description = ''
        Channel to monitor via the NixOS Prometheus `channel_revision` metric.
        Darwin hosts typically want `nixpkgs-unstable` or `nixpkgs-26.05-darwin`;
        NixOS hosts typically want `nixos-unstable` or `nixos-26.05`.
      '';
      example = "nixos-26.05";
    };

    startHour = lib.mkOption {
      type = lib.types.int;
      default = 7;
      description = "Hour to start checking for updates (0-23).";
      example = 8;
    };

    endHour = lib.mkOption {
      type = lib.types.int;
      default = 22;
      description = "Hour to stop checking for updates (0-23).";
      example = 20;
    };

    minute = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Minute of each hour to check for updates (0-59).";
      example = 0;
    };
  };

  config = lib.mkIf cfg.enable (
    {
      assertions = [
        {
          assertion = isLinux || isDarwin;
          message = "services.nixos-update-notify is supported on NixOS and nix-darwin only.";
        }
      ];
    }
    // lib.optionalAttrs isLinux {
      systemd.user.services.nixos-update-notify = {
        description = "Check for NixOS channel updates";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${checkUpdateScript}/bin/nixos-update-notify";
        };
      };

      systemd.user.timers.nixos-update-notify = {
        description = "Hourly NixOS update check";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* ${toString cfg.startHour}..${toString cfg.endHour}:${toString cfg.minute}:00";
          Persistent = true;
        };
      };
    }
    // lib.optionalAttrs isDarwin {
      launchd.user.agents.nixos-update-notify = {
        command = "${checkUpdateScript}/bin/nixos-update-notify";
        serviceConfig = {
          RunAtLoad = true;
          StartCalendarInterval = map (h: {
            Hour = h;
            Minute = cfg.minute;
          }) calendarHours;
          StandardOutPath = "/tmp/nixos-update-notify.log";
          StandardErrorPath = "/tmp/nixos-update-notify.err.log";
        };
      };
    }
  );
}
