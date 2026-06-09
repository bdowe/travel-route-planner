#!/usr/bin/env bash
#
# Continuously probe the gateway and API through the nginx gateway on :3000.
#
# Usage:
#   scripts/healthcheck.sh           # poll every 2s (default)
#   scripts/healthcheck.sh 5         # poll every 5s
#   BASE_URL=http://host:3000 scripts/healthcheck.sh
#
# Notes:
#   - The gateway's /health endpoint returns plain text ("healthy"), so it is
#     NOT piped through jq. The API's /api/v1/health returns JSON.

set -u

BASE_URL="${BASE_URL:-http://localhost:3000}"
INTERVAL="${1:-2}"

while true; do
  clear
  echo "== gateway ($BASE_URL/health) =="
  curl -sf "$BASE_URL/health" && echo || echo 'gateway down'

  echo
  echo "== api ($BASE_URL/api/v1/health) =="
  curl -s "$BASE_URL/api/v1/health" | jq . 2>/dev/null || echo 'api down'

  sleep "$INTERVAL"
done
