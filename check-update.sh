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

# Get local system revision
LOCAL=$(nixos-version --revision)

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
  echo "Already notified about revision ${REMOTE:0:8}"
  exit 0
fi

# New update available - send notification and record it
mkdir -p "$STATE_DIR"
notify-send --urgency=critical \
  "NixOS Update Available" \
  "New $CHANNEL update: ${REMOTE:0:8}..."
printf '%s' "$REMOTE" > "$STATE_FILE"
echo "Notification sent for revision ${REMOTE:0:8}"
