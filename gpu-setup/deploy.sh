#!/bin/bash
# Deploy autoresearch to Akash Network
# Usage: ./deploy.sh
#
# Requires: jq, curl, sshpass
# Reads AKASH_API_KEY from .env or environment

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_BASE="https://console-api.akash.network"

# Load .env from repo root
if [ -f "$SCRIPT_DIR/../.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/../.env" | xargs)
fi

API_KEY="${AKASH_API_KEY:?Set AKASH_API_KEY in .env}"
SDL=$(cat "$SCRIPT_DIR/deploy.yaml")

# --- Step 1: Create deployment ---
echo "[1/4] Creating deployment..."
DEPLOY_RESPONSE=$(curl -s -X POST "$API_BASE/v1/deployments" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d "$(jq -n --arg sdl "$SDL" '{data: {sdl: $sdl, deposit: 5}}')")

DSEQ=$(echo "$DEPLOY_RESPONSE" | jq -r '.data.dseq')
MANIFEST=$(echo "$DEPLOY_RESPONSE" | jq -r '.data.manifest')

if [ "$DSEQ" = "null" ] || [ -z "$DSEQ" ]; then
  echo "Failed to create deployment:"
  echo "$DEPLOY_RESPONSE" | jq .
  exit 1
fi

echo "    dseq: $DSEQ"

# --- Step 2: Wait for bids ---
echo "[2/4] Waiting for bids (20s)..."
sleep 20

BIDS_RESPONSE=$(curl -s "$API_BASE/v1/bids?dseq=$DSEQ" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY")

BID_COUNT=$(echo "$BIDS_RESPONSE" | jq '.data | length')
echo "    $BID_COUNT bids received"

if [ "$BID_COUNT" = "0" ]; then
  echo "No bids. Try adjusting GPU model or pricing in deploy.yaml."
  exit 1
fi

# Show bids
echo "$BIDS_RESPONSE" | jq -r '.data | sort_by(.bid.price.amount | tonumber) | .[] | "    \(.bid.resources_offer[0].resources.gpu.attributes[0].key | split("/") | .[-1]) — price: \(.bid.price.amount | tonumber | . * 100 | round / 100)"'

# Pick cheapest
PROVIDER=$(echo "$BIDS_RESPONSE" | jq -r '.data | sort_by(.bid.price.amount | tonumber) | .[0].bid.id.provider')
GSEQ=$(echo "$BIDS_RESPONSE" | jq -r '.data | sort_by(.bid.price.amount | tonumber) | .[0].bid.id.gseq')
OSEQ=$(echo "$BIDS_RESPONSE" | jq -r '.data | sort_by(.bid.price.amount | tonumber) | .[0].bid.id.oseq')
GPU_MODEL=$(echo "$BIDS_RESPONSE" | jq -r '.data | sort_by(.bid.price.amount | tonumber) | .[0].bid.resources_offer[0].resources.gpu.attributes[0].key | split("/") | .[-1]')

echo "    selected: $GPU_MODEL ($PROVIDER)"

# --- Step 3: Create lease ---
echo "[3/4] Creating lease..."
LEASE_RESPONSE=$(curl -s -X POST "$API_BASE/v1/leases" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d "$(jq -n \
    --arg manifest "$MANIFEST" \
    --arg dseq "$DSEQ" \
    --argjson gseq "$GSEQ" \
    --argjson oseq "$OSEQ" \
    --arg provider "$PROVIDER" \
    '{manifest: $manifest, leases: [{dseq: $dseq, gseq: $gseq, oseq: $oseq, provider: $provider}]}')")

STATE=$(echo "$LEASE_RESPONSE" | jq -r '.data.deployment.state')
HOST=$(echo "$LEASE_RESPONSE" | jq -r '.data.leases[0].status.forwarded_ports.autoresearch[0].host // empty')
PORT=$(echo "$LEASE_RESPONSE" | jq -r '.data.leases[0].status.forwarded_ports.autoresearch[0].externalPort // empty')

echo "    state: $STATE"

# --- Step 4: Wait for container + SSH ---
echo "[4/4] Waiting for container to boot..."
sleep 30

# Re-fetch to get ports if they weren't in the lease response
if [ -z "$HOST" ] || [ -z "$PORT" ]; then
  DEPLOY_STATUS=$(curl -s "$API_BASE/v1/deployments/$DSEQ" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY")
  HOST=$(echo "$DEPLOY_STATUS" | jq -r '.data.leases[0].status.forwarded_ports.autoresearch[0].host')
  PORT=$(echo "$DEPLOY_STATUS" | jq -r '.data.leases[0].status.forwarded_ports.autoresearch[0].externalPort')
fi

# Save connection info
cat > "$SCRIPT_DIR/.deployment" <<EOF
DSEQ=$DSEQ
HOST=$HOST
PORT=$PORT
PROVIDER=$PROVIDER
GPU_MODEL=$GPU_MODEL
EOF

echo ""
echo "=== Deployment live ==="
echo "  GPU:      $GPU_MODEL"
echo "  dseq:     $DSEQ"
echo "  SSH:      sshpass -p 'autoresearch' ssh -p $PORT root@$HOST"
echo "  Password: autoresearch"
echo ""
echo "Container is installing deps + downloading data (~5 min)."
echo "Once ready, SSH in and run: cd /workspace/autoresearch && uv run train.py"
echo ""
echo "To tear down: ./teardown.sh"
