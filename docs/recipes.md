# Integration recipes

Practical patterns for engineers using [RevAddr](https://revaddr.com). Pair these with the language samples under `examples/`.

## 1. Trust the quality fields

Never ship `formatted_address` alone for delivery, compliance, or enforcement.

| Field | Use it for |
|-------|------------|
| `match_type` | `address_point` is strongest; `area` / `none` need a fallback UX |
| `confidence` | Relative score 0 to 1; drop or flag low values |
| `distance_meters` | If large, the pin may not be at the labeled building |

Example rule of thumb (tune per product):

- Accept if `match_type` is `address_point` or `interpolated` **and** `distance_meters` is under your threshold (for example 50 m for last-mile).
- Soft-warn if `street_only`.
- Prompt the user to confirm if `area` or `none`.

## 2. Cache stable results

If the same coordinate is queried often (dashboard tiles, repeated device pings):

1. Round lat/lon to a precision you accept (for example 5 decimals ~1 m) for the cache key.
2. Store the full `result` object plus retrieved-at timestamp.
3. Revalidate on a schedule that matches your accuracy needs.

Caching reduces cost (each reverse is 1 unit) and latency. Respect privacy laws for stored locations.

## 3. Batch backfills

For CSV/DB imports:

1. Read rows with lat/lon.
2. Chunk into groups of **at most 100**.
3. `POST /v1/reverse/batch` with `{"points":[...]}`.
4. Write back `formatted_address`, `match_type`, `confidence`, `distance_meters`.
5. Retry transient 5xx / 429 with exponential backoff and jitter.

See `examples/python/batch.py`, `examples/node/batch.mjs`, `examples/curl/batch.sh`, `examples/r/batch.R`.

## 4. Mobile GPS (Kotlin / Swift / Dart)

Recommended architecture:

```text
Phone GPS  -->  Your backend  -->  RevAddr API
                     ^
                     |
              API key stays on server
```

Client-side keys in mobile binaries get extracted. If you must call from the device, use a restricted key, low balance, and monitor abuse.

## 5. Map click / pin drop

1. User places a pin (or moves a marker).
2. Debounce 200 to 400 ms so you do not reverse on every drag frame.
3. Call reverse once; show `formatted_address` under the pin.
4. If `match_type` is weak, show "Approximate location" and let the user edit.

## 6. Error handling cheat sheet

| HTTP | Meaning | Client action |
|------|---------|----------------|
| 401 | Bad or missing key | Fix `x-api-key` |
| 402 | Out of units | Top up credits |
| 422 | Invalid lat/lon | Validate ranges before send |
| 429 | Rate limited | Back off + retry with jitter |
| 5xx | Server / upstream | Retry a few times; then fail open/closed per product |

## 7. OpenAPI and codegen

Interactive docs: https://api.revaddr.com/docs  

OpenAPI JSON (Swagger UI "openapi.json" from the same host): https://api.revaddr.com/openapi.json  

You can generate clients with openapi-generator, speakeasy, etc. The samples in this repo stay hand-written for clarity and zero lock-in.

## 8. Local env

```bash
cp .env.example .env
# edit .env with your key
export $(grep -v '^#' .env | xargs)   # unix-like shells
```

Never commit `.env` or real keys.
