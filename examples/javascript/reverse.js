/**
 * Browser JavaScript: reverse-geocode with fetch().
 *
 * How it works
 * ------------
 * 1. Build a GET URL for /v1/reverse with lat and lon query params.
 * 2. Send header x-api-key (required for authenticated reverse).
 * 3. Parse JSON {"result": {...}} and use result.formatted_address.
 *
 * Security note
 * -------------
 * Putting a live secret key in front-end code exposes it to every visitor.
 * Prefer calling RevAddr from your backend, or use only keys you intend for
 * public browser use with tight rate limits and low remaining balance.
 *
 * Demo on revaddr.com uses a separate origin-restricted demo endpoint;
 * integrators should use /v1/reverse with their own key.
 *
 * Usage (browser console or bundler, with a key you control):
 *   reverseGeocode(38.8977, -77.0365, "sk_live_...").then(console.log);
 */

const DEFAULT_BASE = "https://api.revaddr.com";

/**
 * @param {number} lat WGS84 latitude
 * @param {number} lon WGS84 longitude
 * @param {string} apiKey RevAddr API key
 * @param {string} [baseUrl]
 * @returns {Promise<object>} the "result" object from the API
 */
export async function reverseGeocode(
  lat,
  lon,
  apiKey,
  baseUrl = DEFAULT_BASE,
) {
  if (!apiKey) {
    throw new Error("apiKey is required");
  }

  // URLSearchParams encodes lat/lon safely for the query string.
  const url = new URL("/v1/reverse", baseUrl);
  url.searchParams.set("lat", String(lat));
  url.searchParams.set("lon", String(lon));

  const res = await fetch(url, {
    method: "GET",
    headers: {
      "x-api-key": apiKey,
      Accept: "application/json",
    },
  });

  // Surface API error bodies (quota, auth) instead of only "HTTP 402".
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`RevAddr HTTP ${res.status}: ${text.slice(0, 400)}`);
  }

  const data = await res.json();
  // Successful single reverse: { "result": { formatted_address, ... } }
  if (!data || typeof data !== "object" || !data.result) {
    throw new Error("Unexpected response shape (missing result)");
  }
  return data.result;
}

// Optional self-test when loaded as a classic script in a page that sets window.
if (typeof window !== "undefined") {
  window.revaddrReverseGeocode = reverseGeocode;
}
