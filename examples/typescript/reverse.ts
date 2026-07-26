/**
 * Typed reverse-geocode client sample for RevAddr (TypeScript, Node 18+).
 *
 * Run:
 *   export REVADDR_API_KEY=sk_live_...
 *   npm install
 *   npx tsx reverse.ts
 *   npx tsx reverse.ts 37.7749 -122.4194
 *
 * Types mirror the public JSON contract so your IDE can autocomplete fields.
 */

const DEFAULT_BASE = "https://api.revaddr.com";

/** One reverse result (the object under "result"). */
export interface ReverseResult {
  formatted_address: string | null;
  house_number: string | null;
  street: string | null;
  city: string | null;
  state: string | null;
  postcode: string | null;
  county: string | null;
  /** address_point | interpolated | street_only | area | none */
  match_type: string;
  confidence: number;
  distance_meters: number | null;
  /** Echo of the query coordinates (not rooftop of the feature). */
  lat: number;
  lon: number;
}

interface ReverseEnvelope {
  result: ReverseResult;
}

export interface ReverseOptions {
  apiKey: string;
  baseUrl?: string;
  /** Abort after this many ms (default 30000). */
  timeoutMs?: number;
}

/**
 * GET /v1/reverse?lat=&lon= with x-api-key auth.
 * Throws on non-2xx or unexpected JSON shape.
 */
export async function reverseGeocode(
  lat: number,
  lon: number,
  options: ReverseOptions,
): Promise<ReverseResult> {
  const baseUrl = (options.baseUrl ?? DEFAULT_BASE).replace(/\/$/, "");
  const url = new URL(`${baseUrl}/v1/reverse`);
  url.searchParams.set("lat", String(lat));
  url.searchParams.set("lon", String(lon));

  const controller = new AbortController();
  const timer = setTimeout(
    () => controller.abort(),
    options.timeoutMs ?? 30_000,
  );

  let res: Response;
  try {
    res = await fetch(url, {
      headers: {
        "x-api-key": options.apiKey,
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

  const data = (await res.json()) as ReverseEnvelope;
  if (!data?.result) {
    throw new Error("Unexpected response shape (missing result)");
  }
  return data.result;
}

async function main(): Promise<void> {
  const apiKey = (process.env.REVADDR_API_KEY ?? "").trim();
  if (!apiKey) {
    console.error(
      "Set REVADDR_API_KEY.\nCreate a free account: https://revaddr.com/create-account.html",
    );
    process.exit(1);
  }

  const baseUrl = (process.env.REVADDR_BASE_URL ?? DEFAULT_BASE).trim();
  const lat = process.argv[2] ? Number(process.argv[2]) : 38.8977;
  const lon = process.argv[3] ? Number(process.argv[3]) : -77.0365;
  if (Number.isNaN(lat) || Number.isNaN(lon)) {
    console.error("Usage: npx tsx reverse.ts [lat lon]");
    process.exit(2);
  }

  const result = await reverseGeocode(lat, lon, { apiKey, baseUrl });
  console.log(result.formatted_address ?? "(no formatted_address)");
  console.log(JSON.stringify(result, null, 2));
}

// Only run CLI when executed directly (not when imported as a module).
const isMain =
  typeof process !== "undefined" &&
  process.argv[1] &&
  (process.argv[1].endsWith("reverse.ts") ||
    process.argv[1].endsWith("reverse.js"));

if (isMain) {
  main().catch((err: unknown) => {
    console.error(err instanceof Error ? err.message : err);
    process.exit(1);
  });
}
