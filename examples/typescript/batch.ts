/**
 * Typed batch reverse for RevAddr (up to 100 points per request).
 *
 * Run:
 *   export REVADDR_API_KEY=sk_live_...
 *   npx tsx batch.ts
 */

import type { ReverseResult } from "./reverse.ts";

const DEFAULT_BASE = "https://api.revaddr.com";

const SAMPLE_POINTS = [
  { lat: 38.8977, lon: -77.0365 },
  { lat: 37.7749, lon: -122.4194 },
  { lat: 40.7128, lon: -74.006 },
];

interface BatchEnvelope {
  results: ReverseResult[];
}

export async function reverseBatch(
  points: Array<{ lat: number; lon: number }>,
  options: { apiKey: string; baseUrl?: string },
): Promise<ReverseResult[]> {
  if (points.length === 0) throw new Error("points must not be empty");
  if (points.length > 100) throw new Error("max 100 points per batch");

  const baseUrl = (options.baseUrl ?? DEFAULT_BASE).replace(/\/$/, "");
  const url = new URL(`${baseUrl}/v1/reverse/batch`);

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 60_000);

  let res: Response;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: {
        "x-api-key": options.apiKey,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
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

  const data = (await res.json()) as BatchEnvelope;
  return data.results;
}

async function main(): Promise<void> {
  const apiKey = (process.env.REVADDR_API_KEY ?? "").trim();
  if (!apiKey) {
    console.error("Set REVADDR_API_KEY.");
    process.exit(1);
  }
  const baseUrl = (process.env.REVADDR_BASE_URL ?? DEFAULT_BASE).trim();

  const results = await reverseBatch(SAMPLE_POINTS, { apiKey, baseUrl });
  results.forEach((r, i) => {
    const p = SAMPLE_POINTS[i];
    console.log(
      `[${i}] (${p.lat}, ${p.lon}) -> ${r.formatted_address ?? "(none)"}`,
    );
  });
  console.log(JSON.stringify(results, null, 2));
}

main().catch((err: unknown) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
