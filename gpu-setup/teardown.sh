#!/bin/bash
# Tear down an Akash deployment
# Usage: ./teardown.sh [dseq]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_BASE="https://console-api.akash.network"

if [ -f "$SCRIPT_DIR/../.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/../.env" | xargs)
fi

API_KEY="${AKASH_API_KEY:?Set AKASH_API_KEY in .env}"

# Get dseq from arg, .deployment file, or list deployments
DSEQ="${1:-}"

if [ -z "$DSEQ" ] && [ -f "$SCRIPT_DIR/.deployment" ]; then
  source "$SCRIPT_DIR/.deployment"
fi

if [ -z "$DSEQ" ]; then
  echo "No dseq provided. Active deployments:"
  curl -s "$API_BASE/v1/deployments?skip=0&limit=10" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY" | jq -r '.data.deployments[] | "  \(.deployment.id.dseq) — \(.deployment.state)"'
  echo ""
  echo "Usage: ./teardown.sh <dseq>"
  exit 1
fi

echo "Closing deployment $DSEQ..."
RESPONSE=$(curl -s -X DELETE "$API_BASE/v1/deployments/$DSEQ" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY")

SUCCESS=$(echo "$RESPONSE" | jq -r '.data.success // false')

if [ "$SUCCESS" = "true" ]; then
  echo "Deployment $DSEQ closed. Remaining deposit returned."
  rm -f "$SCRIPT_DIR/.deployment"
else
  echo "Failed to close deployment:"
  echo "$RESPONSE" | jq .
fi
