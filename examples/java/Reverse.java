/**
 * Reverse-geocode a single point with RevAddr (Java 11+ HttpClient).
 *
 * Compile and run:
 *   export REVADDR_API_KEY=sk_live_...
 *   javac Reverse.java
 *   java Reverse
 *   java Reverse 37.7749 -122.4194
 *
 * How it works: GET /v1/reverse with x-api-key, parse JSON for result.formatted_address.
 * This sample prints the full body; for production prefer a JSON library (Jackson/Gson).
 */

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

public class Reverse {
    private static final String DEFAULT_BASE = "https://api.revaddr.com";

    public static void main(String[] args) throws Exception {
        String apiKey = System.getenv("REVADDR_API_KEY");
        if (apiKey == null || apiKey.isBlank()) {
            System.err.println("Set REVADDR_API_KEY to your RevAddr API key.");
            System.exit(1);
        }

        String base = System.getenv("REVADDR_BASE_URL");
        if (base == null || base.isBlank()) {
            base = DEFAULT_BASE;
        }

        // Defaults match the website hero example.
        double lat = 38.8977;
        double lon = -77.0365;
        if (args.length >= 2) {
            lat = Double.parseDouble(args[0]);
            lon = Double.parseDouble(args[1]);
        }

        // Build query string with UTF-8 encoding (Invariant decimal form is fine for doubles).
        String query =
            "lat=" + URLEncoder.encode(Double.toString(lat), StandardCharsets.UTF_8)
                + "&lon=" + URLEncoder.encode(Double.toString(lon), StandardCharsets.UTF_8);
        URI uri = URI.create(base.replaceAll("/$", "") + "/v1/reverse?" + query);

        HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

        // Auth and Accept headers on every reverse call.
        HttpRequest request = HttpRequest.newBuilder(uri)
            .timeout(Duration.ofSeconds(30))
            .header("x-api-key", apiKey.trim())
            .header("Accept", "application/json")
            .GET()
            .build();

        HttpResponse<String> response =
            client.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            System.err.println("HTTP " + response.statusCode() + ": " + response.body());
            System.exit(1);
        }

        // Full JSON: {"result":{"formatted_address":"...", ...}}
        System.out.println(response.body());
    }
}
