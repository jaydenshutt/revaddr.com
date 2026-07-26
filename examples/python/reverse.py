#!/usr/bin/env python3
"""
Reverse-geocode a single latitude/longitude with RevAddr (Python).

What this does
--------------
1. Reads your API key from the environment (never hard-code secrets).
2. Calls GET https://api.revaddr.com/v1/reverse?lat=...&lon=...
3. Parses the JSON envelope {"result": {...}} and prints the address.

Install:
    pip install -r requirements.txt

Run:
    export REVADDR_API_KEY="sk_live_..."
    python reverse.py
    python reverse.py 37.7749 -122.4194
"""

from __future__ import annotations

import json
import os
import sys
from typing import Any

import requests

# Production API host. Override with REVADDR_BASE_URL for staging or self-hosted mirrors.
DEFAULT_BASE = "https://api.revaddr.com"
# Demo point used on revaddr.com (White House).
DEFAULT_LAT = 38.8977
DEFAULT_LON = -77.0365


def reverse(lat: float, lon: float, *, api_key: str, base_url: str) -> dict[str, Any]:
    """
    Call GET /v1/reverse and return the parsed "result" object.

    Raises:
        requests.HTTPError: non-2xx response (auth, quota, validation, etc.)
        KeyError / TypeError: unexpected response shape
    """
    url = f"{base_url.rstrip('/')}/v1/reverse"
    # Auth is a custom header, not a query parameter (do not put keys in URLs/logs).
    headers = {
        "x-api-key": api_key,
        "Accept": "application/json",
    }
    params = {"lat": lat, "lon": lon}

    # timeout=(connect, read) seconds: fail rather than hang forever.
    response = requests.get(url, params=params, headers=headers, timeout=(5, 30))
    # Raise for 4xx/5xx so callers do not treat error HTML/JSON as a success.
    response.raise_for_status()
    payload = response.json()
    # Successful reverse responses are always wrapped: {"result": { ...fields... }}
    return payload["result"]


def main(argv: list[str]) -> int:
    api_key = os.environ.get("REVADDR_API_KEY", "").strip()
    if not api_key:
        print(
            "Set REVADDR_API_KEY to your RevAddr API key.\n"
            "Create a free account: https://revaddr.com/create-account.html",
            file=sys.stderr,
        )
        return 1

    base_url = os.environ.get("REVADDR_BASE_URL", DEFAULT_BASE).strip() or DEFAULT_BASE

    try:
        lat = float(argv[1]) if len(argv) > 1 else DEFAULT_LAT
        lon = float(argv[2]) if len(argv) > 2 else DEFAULT_LON
    except ValueError:
        print("Usage: reverse.py [lat lon]", file=sys.stderr)
        return 2

    try:
        result = reverse(lat, lon, api_key=api_key, base_url=base_url)
    except requests.HTTPError as exc:
        # Include body when present: helps debug 401/402/429 messages from the API.
        body = ""
        if exc.response is not None:
            body = (exc.response.text or "")[:500]
        print(f"HTTP error: {exc}\n{body}", file=sys.stderr)
        return 1
    except (requests.RequestException, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"Request failed: {exc}", file=sys.stderr)
        return 1

    # Primary human-readable line for UIs and logs.
    print(result.get("formatted_address") or "(no formatted_address)")
    # Structured fields + quality metadata (match_type, confidence, distance_meters).
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
