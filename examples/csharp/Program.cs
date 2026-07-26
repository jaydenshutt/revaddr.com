// Reverse-geocode with RevAddr using HttpClient + System.Text.Json (.NET 8).
//
// Run:
//   set REVADDR_API_KEY=sk_live_...   (Windows cmd)
//   export REVADDR_API_KEY=sk_live_... (bash)
//   dotnet run --project .
//   dotnet run --project . -- 37.7749 -122.4194

using System.Globalization;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;

const string DefaultBase = "https://api.revaddr.com";

// Nested DTOs match the public JSON contract.
sealed class ReverseEnvelope
{
    [JsonPropertyName("result")]
    public ReverseResult? Result { get; set; }
}

sealed class ReverseResult
{
    [JsonPropertyName("formatted_address")]
    public string? FormattedAddress { get; set; }

    [JsonPropertyName("house_number")]
    public string? HouseNumber { get; set; }

    [JsonPropertyName("street")]
    public string? Street { get; set; }

    [JsonPropertyName("city")]
    public string? City { get; set; }

    [JsonPropertyName("state")]
    public string? State { get; set; }

    [JsonPropertyName("postcode")]
    public string? Postcode { get; set; }

    [JsonPropertyName("county")]
    public string? County { get; set; }

    [JsonPropertyName("match_type")]
    public string? MatchType { get; set; }

    [JsonPropertyName("confidence")]
    public double Confidence { get; set; }

    [JsonPropertyName("distance_meters")]
    public double? DistanceMeters { get; set; }

    [JsonPropertyName("lat")]
    public double Lat { get; set; }

    [JsonPropertyName("lon")]
    public double Lon { get; set; }
}

var apiKey = Environment.GetEnvironmentVariable("REVADDR_API_KEY")?.Trim();
if (string.IsNullOrEmpty(apiKey))
{
    Console.Error.WriteLine("Set REVADDR_API_KEY to your RevAddr API key.");
    return 1;
}

var baseUrl = Environment.GetEnvironmentVariable("REVADDR_BASE_URL")?.Trim();
if (string.IsNullOrEmpty(baseUrl))
    baseUrl = DefaultBase;

// White House default; optional CLI overrides.
double lat = 38.8977;
double lon = -77.0365;
if (args.Length >= 2)
{
    if (!double.TryParse(args[0], NumberStyles.Float, CultureInfo.InvariantCulture, out lat) ||
        !double.TryParse(args[1], NumberStyles.Float, CultureInfo.InvariantCulture, out lon))
    {
        Console.Error.WriteLine("Usage: dotnet run -- [lat lon]");
        return 2;
    }
}

using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
// DefaultRequestHeaders apply to every call from this client instance.
client.DefaultRequestHeaders.Add("x-api-key", apiKey);
client.DefaultRequestHeaders.Accept.Add(
    new MediaTypeWithQualityHeaderValue("application/json"));

// GET /v1/reverse?lat=&lon=
var url =
    $"{baseUrl.TrimEnd('/')}/v1/reverse?lat={lat.ToString(CultureInfo.InvariantCulture)}" +
    $"&lon={lon.ToString(CultureInfo.InvariantCulture)}";

using var response = await client.GetAsync(url);
var body = await response.Content.ReadAsStringAsync();
if (!response.IsSuccessStatusCode)
{
    Console.Error.WriteLine($"HTTP {(int)response.StatusCode}: {body}");
    return 1;
}

var envelope = JsonSerializer.Deserialize<ReverseEnvelope>(body);
var result = envelope?.Result;
if (result is null)
{
    Console.Error.WriteLine("Unexpected response: missing result");
    return 1;
}

Console.WriteLine(result.FormattedAddress ?? "(no formatted_address)");
Console.WriteLine(JsonSerializer.Serialize(result, new JsonSerializerOptions { WriteIndented = true }));
return 0;
