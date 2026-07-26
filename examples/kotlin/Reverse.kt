/**
 * Reverse-geocode a single lat/lon with RevAddr (Kotlin, JVM).
 *
 * Requirements: JDK 11+, Kotlin compiler. No third-party deps (java.net.http).
 *
 * Run:
 *   export REVADDR_API_KEY=sk_live_...
 *   kotlinc Reverse.kt -include-runtime -d reverse.jar
 *   java -jar reverse.jar
 *   java -jar reverse.jar 37.7749 -122.4194
 *
 * Android/backend: copy reverseGeocode() into a repository class and load the
 * API key from secrets (never commit keys; avoid logging full keys).
 */

import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.charset.StandardCharsets
import java.time.Duration
import kotlin.system.exitProcess

const val DEFAULT_BASE = "https://api.revaddr.com"

/**
 * GET /v1/reverse and return the raw JSON body.
 * Production apps should map fields into a data class (kotlinx.serialization / Moshi).
 */
fun reverseGeocode(
    lat: Double,
    lon: Double,
    apiKey: String,
    baseUrl: String = DEFAULT_BASE,
): String {
    require(apiKey.isNotBlank()) { "apiKey is required" }

    val base = baseUrl.trimEnd('/')
    val query =
        "lat=" + URLEncoder.encode(lat.toString(), StandardCharsets.UTF_8) +
            "&lon=" + URLEncoder.encode(lon.toString(), StandardCharsets.UTF_8)
    val uri = URI.create("$base/v1/reverse?$query")

    val client =
        HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build()

    // Auth is always the x-api-key header (never a query param).
    val request =
        HttpRequest.newBuilder(uri)
            .timeout(Duration.ofSeconds(30))
            .header("x-api-key", apiKey)
            .header("Accept", "application/json")
            .GET()
            .build()

    val response = client.send(request, HttpResponse.BodyHandlers.ofString())
    if (response.statusCode() !in 200..299) {
        throw RuntimeException("HTTP ${response.statusCode()}: ${response.body()}")
    }
    return response.body()
}

/** Minimal pull of result.formatted_address without a JSON library (demo only). */
fun formattedAddressFromBody(body: String): String? {
    val key = "\"formatted_address\""
    val i = body.indexOf(key)
    if (i < 0) return null
    val colon = body.indexOf(':', i + key.length)
    val firstQuote = body.indexOf('"', colon + 1)
    if (firstQuote < 0) return null
    val secondQuote = body.indexOf('"', firstQuote + 1)
    if (secondQuote < 0) return null
    return body.substring(firstQuote + 1, secondQuote)
}

fun main(args: Array<String>) {
    val apiKey = System.getenv("REVADDR_API_KEY")?.trim().orEmpty()
    if (apiKey.isEmpty()) {
        System.err.println("Set REVADDR_API_KEY to your RevAddr API key.")
        exitProcess(1)
    }
    val base = System.getenv("REVADDR_BASE_URL")?.trim()?.ifEmpty { null } ?: DEFAULT_BASE

    // Defaults match the website hero example (White House).
    val lat = args.getOrNull(0)?.toDoubleOrNull() ?: 38.8977
    val lon = args.getOrNull(1)?.toDoubleOrNull() ?: -77.0365

    try {
        val body = reverseGeocode(lat, lon, apiKey, base)
        println(formattedAddressFromBody(body) ?: "(no formatted_address)")
        println(body)
    } catch (e: Exception) {
        System.err.println(e.message)
        exitProcess(1)
    }
}
