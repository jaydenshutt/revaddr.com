#!/usr/bin/env bash
# Reverse-geocode one lat/lon with the RevAddr HTTP API (curl).
#
# Usage:
#   export REVADDR_API_KEY="sk_live_..."
#   ./reverse.sh
#   ./reverse.sh 37.7749 -122.4194
#
# Optional:
#   REVADDR_BASE_URL  default https://api.revaddr.com

set -euo pipefail

BASE_URL="${REVADDR_BASE_URL:-https://api.revaddr.com}"
API_KEY="${REVADDR_API_KEY:-}"

if [[ -z "${API_KEY}" ]]; then
  echo "Set REVADDR_API_KEY to your RevAddr API key." >&2
  echo "Get one free at https://revaddr.com/create-account.html" >&2
  exit 1
fi

# Default demo point: White House (matches the website hero example).
LAT="${1:-38.8977}"
LON="${2:--77.0365}"

# GET /v1/reverse?lat=&lon= with the required auth header.
# -f fails on HTTP error status; -S shows curl errors; -s silences progress.
curl -fsS \
  -H "x-api-key: ${API_KEY}" \
  -H "Accept: application/json" \
  --get \
  --data-urlencode "lat=${LAT}" \
  --data-urlencode "lon=${LON}" \
  "${BASE_URL}/v1/reverse"

echo
