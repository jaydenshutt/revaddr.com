<?php
/**
 * Reverse-geocode a single point with RevAddr (PHP 8+, cURL extension).
 *
 * Run:
 *   export REVADDR_API_KEY=sk_live_...
 *   php reverse.php
 *   php reverse.php 37.7749 -122.4194
 */

declare(strict_types=1);

const DEFAULT_BASE = 'https://api.revaddr.com';

$apiKey = getenv('REVADDR_API_KEY') ?: '';
if ($apiKey === '') {
    fwrite(STDERR, "Set REVADDR_API_KEY to your RevAddr API key.\n");
    exit(1);
}

$base = getenv('REVADDR_BASE_URL') ?: DEFAULT_BASE;
$base = rtrim($base, '/');

// Website hero default: White House.
$lat = isset($argv[1]) ? (float) $argv[1] : 38.8977;
$lon = isset($argv[2]) ? (float) $argv[2] : -77.0365;

// http_build_query encodes lat/lon correctly for the query string.
$query = http_build_query(['lat' => $lat, 'lon' => $lon], '', '&', PHP_QUERY_RFC3986);
$url = $base . '/v1/reverse?' . $query;

$ch = curl_init($url);
if ($ch === false) {
    fwrite(STDERR, "curl_init failed\n");
    exit(1);
}

// CURLOPT_HTTPHEADER carries the secret; never put keys in the URL.
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 30,
    CURLOPT_HTTPHEADER => [
        'x-api-key: ' . $apiKey,
        'Accept: application/json',
    ],
]);

$body = curl_exec($ch);
$status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
$err = curl_error($ch);
curl_close($ch);

if ($body === false) {
    fwrite(STDERR, "curl error: {$err}\n");
    exit(1);
}
if ($status < 200 || $status >= 300) {
    fwrite(STDERR, "HTTP {$status}: {$body}\n");
    exit(1);
}

$data = json_decode($body, true);
if (!is_array($data) || !isset($data['result'])) {
    fwrite(STDERR, "Unexpected response shape\n");
    exit(1);
}

$result = $data['result'];
// Prefer formatted_address for display; dump full object for debugging.
echo ($result['formatted_address'] ?? '(no formatted_address)') . PHP_EOL;
echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL;
