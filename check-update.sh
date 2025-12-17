#!/usr/bin/env bash
set -x
set -euo pipefail

CHANNEL="${CHANNEL:-nixos-unstable}"
API_URL="https://prometheus.nixos.org/api/v1/query?query=channel_revision"

# Fetch remote revision from Prometheus API
REMOTE=$(curl -sf "$API_URL" | \
  jq -r ".data.result[] | select(.metric.channel==\"$CHANNEL\") | .metric.revision")

if [ -z "$REMOTE" ]; then
  echo "Error: Could not fetch revision for channel '$CHANNEL'" >&2
  exit 1
fi

# Get local system revision
LOCAL=$(nixos-version --revision)

if [ "$REMOTE" != "$LOCAL" ]; then
  notify-send --urgency=critical \
    "NixOS Update Available" \
    "New $CHANNEL update: ${REMOTE:0:8}..."
fi
