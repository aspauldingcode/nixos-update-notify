#!/usr/bin/env bash
set -euo pipefail

CHANNEL="${CHANNEL:-nixos-unstable}"
API_URL="https://prometheus.nixos.org/api/v1/query?query=channel_revision"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-update-notify"
STATE_FILE="$STATE_DIR/last-notified-revision"

# Fetch remote revision from Prometheus API
REMOTE=$(curl -sf "$API_URL" | \
  jq -r ".data.result[] | select(.metric.channel==\"$CHANNEL\") | .metric.revision")

if [ -z "$REMOTE" ]; then
  echo "Error: Could not fetch revision for channel '$CHANNEL'" >&2
  exit 1
fi

# Local nixpkgs revision of the running system:
#   NixOS:      nixos-version --revision
#   nix-darwin: darwin-version.json.nixpkgsRevision
local_nixpkgs_revision() {
  if [ -f /run/current-system/darwin-version.json ]; then
    jq -r '.nixpkgsRevision // empty' /run/current-system/darwin-version.json
  elif [ -x /run/current-system/sw/bin/nixos-version ]; then
    /run/current-system/sw/bin/nixos-version --revision
  elif command -v nixos-version >/dev/null 2>&1; then
    nixos-version --revision
  else
    echo "Error: cannot determine local nixpkgs revision" >&2
    return 1
  fi
}

LOCAL=$(local_nixpkgs_revision)
if [ -z "$LOCAL" ]; then
  echo "Error: empty local nixpkgs revision" >&2
  exit 1
fi

# If system is up to date, clear state and exit
if [ "$REMOTE" = "$LOCAL" ]; then
  rm -f "$STATE_FILE"
  echo "Up to date ($CHANNEL ${REMOTE:0:8})"
  exit 0
fi

# Check if we already notified about this revision
LAST_NOTIFIED=""
if [ -f "$STATE_FILE" ]; then
  LAST_NOTIFIED=$(cat "$STATE_FILE")
fi

if [ "$REMOTE" = "$LAST_NOTIFIED" ]; then
  echo "Already notified about revision ${REMOTE:0:8}"
  exit 0
fi

if [ -f /run/current-system/darwin-version.json ]; then
  NOTIFY_TITLE="nix-darwin Update Available"
else
  NOTIFY_TITLE="NixOS Update Available"
fi
NOTIFY_BODY="New $CHANNEL update: ${REMOTE:0:8}..."

mkdir -p "$STATE_DIR"
if command -v notify-send >/dev/null 2>&1; then
  notify-send --urgency=critical "$NOTIFY_TITLE" "$NOTIFY_BODY"
elif command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier -title "$NOTIFY_TITLE" -message "$NOTIFY_BODY" \
    -sound default -timeout 0 >/dev/null
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$NOTIFY_BODY\" with title \"$NOTIFY_TITLE\""
else
  echo "$NOTIFY_TITLE: $NOTIFY_BODY"
fi
printf '%s' "$REMOTE" > "$STATE_FILE"
echo "Notification sent for revision ${REMOTE:0:8}"
