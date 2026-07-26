# RevAddr code samples

[RevAddr](https://revaddr.com) is a reverse geocoding API for the continental United States: send a latitude and longitude, get a structured street address.

This repository is a **public developer kit**: ready-to-run samples in many languages, Postman collection, OpenAPI pointers, and integration recipes. It is meant for engineers wiring reverse geocoding into apps, backends, fleets, IoT, mobile, and analytics.

| | |
|--|--|
| Product site | https://revaddr.com |
| API base | `https://api.revaddr.com` |
| Create a free account | https://revaddr.com/create-account.html |
| Interactive OpenAPI | https://api.revaddr.com/docs |
| OpenAPI notes | [docs/openapi.md](docs/openapi.md) |
| Integration recipes | [docs/recipes.md](docs/recipes.md) |
| Postman collection | [collections/revaddr.postman_collection.json](collections/revaddr.postman_collection.json) |

**Not in this repo:** the geocoding engine, map data, or production service code. Only client examples and integrator docs.

---

## What reverse geocoding is

**Forward geocoding:** address to coordinates  
**Reverse geocoding:** coordinates to address (this product)

Typical flow:

1. You already have a lat/lon (GPS, map pin, photo EXIF, device telemetry).
2. You call `GET /v1/reverse` (or batch) with that point and your API key.
3. RevAddr returns structured fields (`house_number`, `street`, `city`, `state`, `postcode`, `county`) plus quality metadata (`match_type`, `confidence`, `distance_meters`).

Each reverse of one coordinate costs **1 unit** (including low-confidence, area-only, or no-match results). A batch of N points costs N units.

---

## Quick start

1. Create an account and verify email: [create-account.html](https://revaddr.com/create-account.html). You receive a one-time free credit and an API key.
2. Export your key (never hard-code secrets in production):

   ```bash
   export REVADDR_API_KEY="sk_live_..."
   # Windows PowerShell:
   # $env:REVADDR_API_KEY = "sk_live_..."
   ```

3. Run a sample (defaults use the White House: `38.8977, -77.0365`):

   ```bash
   ./examples/curl/reverse.sh
   pip install -r examples/python/requirements.txt && python examples/python/reverse.py
   node examples/node/reverse.mjs
   ```

4. Optional: import [collections/revaddr.postman_collection.json](collections/revaddr.postman_collection.json) into Postman and set the `apiKey` collection variable.

---

## Repository layout

```text
.
├── README.md
├── LICENSE
├── .env.example
├── collections/
│   └── revaddr.postman_collection.json
├── docs/
│   ├── openapi.md
│   └── recipes.md
└── examples/
    ├── curl/          # shell + HTTP (reverse + batch)
    ├── python/        # requests (reverse + batch)
    ├── javascript/    # browser fetch notes
    ├── node/          # Node fetch (reverse + batch)
    ├── typescript/    # typed Node samples (reverse + batch)
    ├── go/            # stdlib
    ├── csharp/        # .NET 8
    ├── java/          # Java 11+ HttpClient
    ├── kotlin/        # JVM Kotlin
    ├── scala/         # Scala 3 / scala-cli
    ├── swift/         # Swift URLSession
    ├── dart/          # Dart / Flutter-friendly
    ├── cpp/  c/       # libcurl
    ├── php/  ruby/    # scripting
    ├── rust/          # reqwest + serde
    ├── powershell/    # Windows automation (reverse + batch)
    ├── r/             # analytics (reverse + batch)
    └── elixir/        # mix + Jason + httpc
```

Every reverse sample:

- Reads **`REVADDR_API_KEY`** from the environment (required).
- Optionally reads **`REVADDR_BASE_URL`** (default `https://api.revaddr.com`).
- Sends **`x-api-key`** on every request.
- Handles HTTP errors and prints `formatted_address` and/or full JSON.
- Uses the same demo coordinates as the public website unless you pass lat/lon args.

---

## Language and tool index

| Stack | Path | How to run (after setting `REVADDR_API_KEY`) |
|-------|------|-----------------------------------------------|
| curl | `examples/curl/` | `./examples/curl/reverse.sh` |
| Python 3 | `examples/python/` | `pip install -r examples/python/requirements.txt && python examples/python/reverse.py` |
| JavaScript (browser) | `examples/javascript/` | See file comments (prefer backend keys) |
| Node.js 18+ | `examples/node/` | `node examples/node/reverse.mjs` |
| TypeScript | `examples/typescript/` | `cd examples/typescript && npm i && npx tsx reverse.ts` |
| Go 1.21+ | `examples/go/` | `cd examples/go && go run .` |
| C# (.NET 8) | `examples/csharp/` | `cd examples/csharp && dotnet run` |
| Java 11+ | `examples/java/` | `javac Reverse.java && java Reverse` |
| Kotlin | `examples/kotlin/` | `kotlinc Reverse.kt -include-runtime -d reverse.jar && java -jar reverse.jar` |
| Scala 3 | `examples/scala/` | `scala-cli Reverse.scala` |
| Swift | `examples/swift/` | `swift main.swift` |
| Dart 3 | `examples/dart/` | `dart pub get && dart run bin/reverse.dart` |
| C++ | `examples/cpp/` | `make && ./reverse` (libcurl) |
| C | `examples/c/` | `make && ./reverse` (libcurl) |
| PHP 8+ | `examples/php/` | `php reverse.php` |
| Ruby 3+ | `examples/ruby/` | `ruby reverse.rb` |
| Rust | `examples/rust/` | `cargo run` |
| PowerShell | `examples/powershell/` | `.\Reverse.ps1` |
| R | `examples/r/` | `Rscript reverse.R` |
| Elixir | `examples/elixir/` | `mix deps.get && mix run -e 'Revaddr.Reverse.main([])'` |
| Postman | `collections/` | Import JSON; set `apiKey` |

Batch samples (where available): `curl`, `python`, `node`, `typescript`, `powershell`, `r`.

---

## API essentials

### Auth

```http
x-api-key: YOUR_API_KEY
```

### Single reverse (GET)

```http
GET /v1/reverse?lat=38.8977&lon=-77.0365
```

### Single reverse (POST)

```http
POST /v1/reverse
Content-Type: application/json

{"lat": 38.8977, "lon": -77.0365}
```

Optional body field: `radius_m` (street search radius in meters).

### Batch reverse

```http
POST /v1/reverse/batch
Content-Type: application/json

{
  "points": [
    {"lat": 38.8977, "lon": -77.0365},
    {"lat": 37.7749, "lon": -122.4194}
  ]
}
```

Up to **100** points per batch request.

### Example response (single reverse)

```json
{
  "result": {
    "formatted_address": "1600 Pennsylvania Ave NW, Washington, DC 20500",
    "house_number": "1600",
    "street": "Pennsylvania Ave NW",
    "city": "Washington",
    "state": "DC",
    "postcode": "20500",
    "county": "District of Columbia",
    "match_type": "address_point",
    "confidence": 1.0,
    "distance_meters": 4.92,
    "lat": 38.8977,
    "lon": -77.0365
  }
}
```

Batch responses use `{"results": [ ... ]}` (array of the same result objects).

### Response fields

| Field | Meaning |
|-------|---------|
| `formatted_address` | Single-line display string |
| `house_number` | Street number when known (else null) |
| `street` | Road name |
| `city` | City or place |
| `state` | Two-letter USPS code |
| `postcode` | ZIP or ZIP+4 when available |
| `county` | County name when known |
| `match_type` | `address_point`, `interpolated`, `street_only`, `area`, or `none` |
| `confidence` | 0 to 1 quality score |
| `distance_meters` | Distance from your query point to the matched feature |
| `lat` / `lon` | Query coordinates echoed back (not rooftop of the feature) |

Coverage is the **continental United States** (lower 48 + DC). Pricing: [revaddr.com/#pricing](https://revaddr.com/#pricing).

---

## Best practices

1. **Never commit API keys.** Use env vars or a secret manager.
2. **Set timeouts.** Fail closed on hung sockets.
3. **Check `match_type` and `distance_meters`.** See [docs/recipes.md](docs/recipes.md).
4. **Prefer batch** for imports and backfills (still 1 unit per point).
5. **Mobile apps:** call RevAddr from your backend when possible.
6. **Rate limits and fair use** apply. See the site Terms and account usage page.

---

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| `401` / auth errors | Key missing, wrong header (`x-api-key`), or key rotated |
| `402` / insufficient units | Top up credits on the account page |
| `429` | Slow down; back off and retry with jitter |
| Empty or weak address | Rural point, water, or outside CONUS; inspect `match_type` |
| Browser CORS failure | Call from your backend |

Still stuck? support@revaddr.com

---

## Contributing

Improvements to samples (clearer comments, more languages, better error handling) are welcome via pull request. Keep examples self-contained and free of secrets.

---

## License

MIT. See [LICENSE](./LICENSE).

RevAddr product, branding, and API service remain property of their owners. This repository only redistributes client examples for developer convenience.
