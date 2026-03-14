#!/bin/bash
# Check status of current Akash deployment
# Usage: ./status.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_BASE="https://console-api.akash.network"

if [ -f "$SCRIPT_DIR/../.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/../.env" | xargs)
fi

API_KEY="${AKASH_API_KEY:?Set AKASH_API_KEY in .env}"

if [ -f "$SCRIPT_DIR/.deployment" ]; then
  source "$SCRIPT_DIR/.deployment"
fi

if [ -z "$DSEQ" ]; then
  echo "No active deployment found. Listing all:"
  curl -s "$API_BASE/v1/deployments?skip=0&limit=10" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY" | jq '.data.deployments[] | {dseq: .deployment.id.dseq, state: .deployment.state}'
  exit 0
fi

RESPONSE=$(curl -s "$API_BASE/v1/deployments/$DSEQ" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY")

echo "$RESPONSE" | jq '{
  dseq: .data.deployment.id.dseq,
  state: .data.deployment.state,
  ready: (.data.leases[0].status.services.autoresearch.ready_replicas // 0),
  host: .data.leases[0].status.forwarded_ports.autoresearch[0].host,
  port: .data.leases[0].status.forwarded_ports.autoresearch[0].externalPort
}'
