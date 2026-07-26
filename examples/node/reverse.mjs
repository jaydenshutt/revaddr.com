/**
 * Node.js 18+: reverse-geocode a single point (native fetch, no npm deps).
 *
 * Run:
 *   export REVADDR_API_KEY="sk_live_..."
 *   node reverse.mjs
 *   node reverse.mjs 37.7749 -122.4194
 */

const DEFAULT_BASE = "https://api.revaddr.com";
const DEFAULT_LAT = 38.8977;
const DEFAULT_LON = -77.0365;

/**
 * GET /v1/reverse and return the inner "result" object.
 */
async function reverse(lat, lon, { apiKey, baseUrl }) {
  const url = new URL("/v1/reverse", baseUrl);
  url.searchParams.set("lat", String(lat));
  url.searchParams.set("lon", String(lon));

  // AbortController enforces a client-side timeout (fetch has no timeout option).
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 30_000);

  let res;
  try {
    res = await fetch(url, {
      headers: {
        "x-api-key": apiKey,
        Accept: "application/json",
      },
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timer);
  }

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`HTTP ${res.status}: ${text.slice(0, 500)}`);
  }

  const data = await res.json();
  return data.result;
}

async function main() {
  const apiKey = (process.env.REVADDR_API_KEY || "").trim();
  if (!apiKey) {
    console.error(
      "Set REVADDR_API_KEY.\nCreate a free account: https://revaddr.com/create-account.html",
    );
    process.exit(1);
  }

  const baseUrl = (process.env.REVADDR_BASE_URL || DEFAULT_BASE).trim();
  const lat = process.argv[2] ? Number(process.argv[2]) : DEFAULT_LAT;
  const lon = process.argv[3] ? Number(process.argv[3]) : DEFAULT_LON;

  if (Number.isNaN(lat) || Number.isNaN(lon)) {
    console.error("Usage: node reverse.mjs [lat lon]");
    process.exit(2);
  }

  const result = await reverse(lat, lon, { apiKey, baseUrl });
  // Human-readable line first, then full structured JSON.
  console.log(result.formatted_address || "(no formatted_address)");
  console.log(JSON.stringify(result, null, 2));
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
