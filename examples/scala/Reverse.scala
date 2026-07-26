/**
 * Reverse-geocode a single lat/lon with RevAddr (Scala 3, JDK HttpClient).
 *
 * Run with scala-cli (recommended):
 *   export REVADDR_API_KEY=sk_live_...
 *   scala-cli Reverse.scala
 *   scala-cli Reverse.scala -- 37.7749 -122.4194
 *
 * Or: scalac Reverse.scala && scala Reverse
 */

//> using scala 3.3
//> using jvm 17

import java.net.URI
import java.net.URLEncoder
import java.net.http.{HttpClient, HttpRequest, HttpResponse}
import java.nio.charset.StandardCharsets
import java.time.Duration

object Reverse:
  val DefaultBase = "https://api.revaddr.com"

  /** GET /v1/reverse; returns raw JSON body or throws on HTTP errors. */
  def reverseGeocode(
      lat: Double,
      lon: Double,
      apiKey: String,
      baseUrl: String = DefaultBase
  ): String =
    require(apiKey.nonEmpty, "apiKey is required")
    val base = baseUrl.stripSuffix("/")
    val q =
      s"lat=${URLEncoder.encode(lat.toString, StandardCharsets.UTF_8)}" +
        s"&lon=${URLEncoder.encode(lon.toString, StandardCharsets.UTF_8)}"
    val uri = URI.create(s"$base/v1/reverse?$q")

    val client = HttpClient
      .newBuilder()
      .connectTimeout(Duration.ofSeconds(5))
      .build()

    // Auth: x-api-key header on every call.
    val request = HttpRequest
      .newBuilder(uri)
      .timeout(Duration.ofSeconds(30))
      .header("x-api-key", apiKey)
      .header("Accept", "application/json")
      .GET()
      .build()

    val response = client.send(request, HttpResponse.BodyHandlers.ofString())
    if response.statusCode() < 200 || response.statusCode() >= 300 then
      throw RuntimeException(s"HTTP ${response.statusCode()}: ${response.body()}")
    response.body()

  def main(args: Array[String]): Unit =
    val apiKey = sys.env.getOrElse("REVADDR_API_KEY", "").trim
    if apiKey.isEmpty then
      System.err.println("Set REVADDR_API_KEY to your RevAddr API key.")
      sys.exit(1)

    val base = sys.env.get("REVADDR_BASE_URL").map(_.trim).filter(_.nonEmpty).getOrElse(DefaultBase)

    // Website hero default: White House.
    val lat = if args.length >= 1 then args(0).toDouble else 38.8977
    val lon = if args.length >= 2 then args(1).toDouble else -77.0365

    try
      val body = reverseGeocode(lat, lon, apiKey, base)
      // Lightweight extract of formatted_address for the first line of output.
      val addr = """"formatted_address"\s*:\s*"([^"]*)"""".r
        .findFirstMatchIn(body)
        .map(_.group(1))
        .getOrElse("(no formatted_address)")
      println(addr)
      println(body)
    catch
      case e: Exception =>
        System.err.println(e.getMessage)
        sys.exit(1)
