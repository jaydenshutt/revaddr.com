/**
 * Node.js: batch reverse up to 100 points (POST /v1/reverse/batch).
 *
 * Run:
 *   export REVADDR_API_KEY="sk_live_..."
 *   node batch.mjs
 */

const DEFAULT_BASE = "https://api.revaddr.com";

const SAMPLE_POINTS = [
  { lat: 38.8977, lon: -77.0365 },
  { lat: 37.7749, lon: -122.4194 },
  { lat: 40.7128, lon: -74.006 },
];

async function reverseBatch(points, { apiKey, baseUrl }) {
  if (!points.length) throw new Error("points must not be empty");
  if (points.length > 100) throw new Error("max 100 points per batch");

  const url = new URL("/v1/reverse/batch", baseUrl);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 60_000);

  let res;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      // Body shape: { "points": [ { "lat": number, "lon": number }, ... ] }
      body: JSON.stringify({ points }),
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
  // Batch envelope uses "results" (plural), not "result".
  return data.results;
}

async function main() {
  const apiKey = (process.env.REVADDR_API_KEY || "").trim();
  if (!apiKey) {
    console.error("Set REVADDR_API_KEY.");
    process.exit(1);
  }
  const baseUrl = (process.env.REVADDR_BASE_URL || DEFAULT_BASE).trim();

  const results = await reverseBatch(SAMPLE_POINTS, { apiKey, baseUrl });
  results.forEach((r, i) => {
    const p = SAMPLE_POINTS[i];
    console.log(`[${i}] (${p.lat}, ${p.lon}) -> ${r.formatted_address || "(none)"}`);
  });
  console.log(JSON.stringify(results, null, 2));
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
