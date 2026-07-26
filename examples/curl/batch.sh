#!/usr/bin/env bash
# Reverse-geocode multiple points in one request (POST /v1/reverse/batch).
# Each point costs 1 unit. Maximum 100 points per request.
#
# Usage:
#   export REVADDR_API_KEY="sk_live_..."
#   ./batch.sh

set -euo pipefail

BASE_URL="${REVADDR_BASE_URL:-https://api.revaddr.com}"
API_KEY="${REVADDR_API_KEY:-}"

if [[ -z "${API_KEY}" ]]; then
  echo "Set REVADDR_API_KEY to your RevAddr API key." >&2
  exit 1
fi

# JSON body: array of {lat, lon} under "points".
BODY='{
  "points": [
    {"lat": 38.8977, "lon": -77.0365},
    {"lat": 37.7749, "lon": -122.4194},
    {"lat": 40.7128, "lon": -74.0060}
  ]
}'

curl -fsS \
  -X POST \
  -H "x-api-key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "${BODY}" \
  "${BASE_URL}/v1/reverse/batch"

echo
