{ config, lib, pkgs, ... }:

let
  cfg = config.services.nixos-update-notify;

  checkUpdateScript = pkgs.writeShellApplication {
    name = "nixos-update-notify";
    runtimeInputs = with pkgs; [ curl jq libnotify ];
    text = ''
      CHANNEL="${cfg.channel}"
      API_URL="https://prometheus.nixos.org/api/v1/query?query=channel_revision"
      STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/nixos-update-notify"
      STATE_FILE="$STATE_DIR/last-notified-revision"

      # Fetch remote revision from Prometheus API
      REMOTE=$(curl -sf "$API_URL" | \
        jq -r ".data.result[] | select(.metric.channel==\"$CHANNEL\") | .metric.revision")

      if [ -z "$REMOTE" ]; then
        echo "Error: Could not fetch revision for channel '$CHANNEL'" >&2
        exit 1
      fi

      # Get local system revision
      LOCAL=$(/run/current-system/sw/bin/nixos-version --revision)

      # If system is up to date, clear state and exit
      if [ "$REMOTE" = "$LOCAL" ]; then
        rm -f "$STATE_FILE"
        exit 0
      fi

      # Check if we already notified about this revision
      LAST_NOTIFIED=""
      if [ -f "$STATE_FILE" ]; then
        LAST_NOTIFIED=$(cat "$STATE_FILE")
      fi

      if [ "$REMOTE" = "$LAST_NOTIFIED" ]; then
        # Already notified about this revision
        exit 0
      fi

      # New update available - send notification and record it
      mkdir -p "$STATE_DIR"
      notify-send --urgency=critical \
        "NixOS Update Available" \
        "New $CHANNEL update: ''${REMOTE:0:8}..."
      printf '%s' "$REMOTE" > "$STATE_FILE"
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

  config = lib.mkIf cfg.enable {
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
  };
}
