#!/usr/bin/env python3
"""
Batch reverse-geocode up to 100 points in one HTTP call.

Why batch?
----------
Backfills and imports often have thousands of coordinates. Batching reduces
HTTP overhead while billing stays simple: 1 unit per point (same as single reverse).

Run:
    export REVADDR_API_KEY="sk_live_..."
    python batch.py
"""

from __future__ import annotations

import json
import os
import sys
from typing import Any

import requests

DEFAULT_BASE = "https://api.revaddr.com"

# Sample CONUS points (DC, San Francisco, NYC).
SAMPLE_POINTS = [
    {"lat": 38.8977, "lon": -77.0365},
    {"lat": 37.7749, "lon": -122.4194},
    {"lat": 40.7128, "lon": -74.0060},
]


def reverse_batch(
    points: list[dict[str, float]],
    *,
    api_key: str,
    base_url: str,
) -> list[dict[str, Any]]:
    """
    POST /v1/reverse/batch with {"points": [{"lat": ..., "lon": ...}, ...]}.

    Returns the "results" array (same fields as a single reverse "result").
    """
    if not points:
        raise ValueError("points must not be empty")
    if len(points) > 100:
        raise ValueError("API allows at most 100 points per batch request")

    url = f"{base_url.rstrip('/')}/v1/reverse/batch"
    headers = {
        "x-api-key": api_key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    response = requests.post(
        url,
        headers=headers,
        json={"points": points},
        timeout=(5, 60),
    )
    response.raise_for_status()
    payload = response.json()
    return payload["results"]


def main() -> int:
    api_key = os.environ.get("REVADDR_API_KEY", "").strip()
    if not api_key:
        print("Set REVADDR_API_KEY.", file=sys.stderr)
        return 1

    base_url = os.environ.get("REVADDR_BASE_URL", DEFAULT_BASE).strip() or DEFAULT_BASE

    try:
        results = reverse_batch(SAMPLE_POINTS, api_key=api_key, base_url=base_url)
    except requests.HTTPError as exc:
        body = ""
        if exc.response is not None:
            body = (exc.response.text or "")[:500]
        print(f"HTTP error: {exc}\n{body}", file=sys.stderr)
        return 1
    except (requests.RequestException, KeyError, TypeError, ValueError) as exc:
        print(f"Request failed: {exc}", file=sys.stderr)
        return 1

    for i, (point, result) in enumerate(zip(SAMPLE_POINTS, results)):
        addr = result.get("formatted_address") or "(none)"
        print(f"[{i}] ({point['lat']}, {point['lon']}) -> {addr}")

    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
