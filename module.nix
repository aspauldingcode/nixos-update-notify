{ config, lib, pkgs, ... }:

let
  cfg = config.services.nixos-update-notify;

  checkUpdateScript = pkgs.writeShellApplication {
    name = "nixos-update-notify";
    runtimeInputs = with pkgs; [ curl jq libnotify ];
    text = ''
      CHANNEL="${cfg.channel}"
      API_URL="https://prometheus.nixos.org/api/v1/query?query=channel_revision"

      # Fetch remote revision from Prometheus API
      REMOTE=$(curl -sf "$API_URL" | \
        jq -r ".data.result[] | select(.metric.channel==\"$CHANNEL\") | .metric.revision")

      if [ -z "$REMOTE" ]; then
        echo "Error: Could not fetch revision for channel '$CHANNEL'" >&2
        exit 1
      fi

      # Get local system revision
      LOCAL=$(/run/current-system/sw/bin/nixos-version --revision)

      if [ "$REMOTE" != "$LOCAL" ]; then
        notify-send --urgency=critical \
          "NixOS Update Available" \
          "New $CHANNEL update: ''${REMOTE:0:8}..."
      fi
    '';
  };
in
{
  options.services.nixos-update-notify = {
    enable = lib.mkEnableOption "NixOS update notifier";

    channel = lib.mkOption {
      type = lib.types.str;
      default = "nixos-unstable";
      description = "The NixOS channel to monitor for updates.";
      example = "nixos-25.11";
    };

    time = lib.mkOption {
      type = lib.types.str;
      default = "07:30";
      description = "Time to check for updates (HH:MM format).";
      example = "09:00";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.nixos-update-notify = {
      description = "Check for NixOS channel updates";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${checkUpdateScript}/bin/nixos-update-notify";
      };
    };

    systemd.user.timers.nixos-update-notify = {
      description = "Daily NixOS update check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* ${cfg.time}:00";
        Persistent = true;
      };
    };
  };
}
