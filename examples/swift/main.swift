// Reverse-geocode a single lat/lon with RevAddr (Swift 5.5+, Foundation).
//
// Run (macOS / Linux with Swift toolchain):
//   export REVADDR_API_KEY=sk_live_...
//   swift main.swift
//   swift main.swift 37.7749 -122.4194
//
// iOS: prefer proxying through your backend so the API key is not in the app binary.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Dispatch)
import Dispatch
#endif

let defaultBase = "https://api.revaddr.com"

struct ReverseEnvelope: Decodable {
    let result: ReverseResult
}

/// Fields match the public API JSON (snake_case via CodingKeys).
struct ReverseResult: Decodable {
    let formattedAddress: String?
    let houseNumber: String?
    let street: String?
    let city: String?
    let state: String?
    let postcode: String?
    let county: String?
    let matchType: String?
    let confidence: Double?
    let distanceMeters: Double?
    let lat: Double?
    let lon: Double?

    enum CodingKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
        case houseNumber = "house_number"
        case street, city, state, postcode, county
        case matchType = "match_type"
        case confidence
        case distanceMeters = "distance_meters"
        case lat, lon
    }
}

enum RevAddrError: Error, CustomStringConvertible {
    case missingAPIKey
    case http(Int, String)
    case badURL

    var description: String {
        switch self {
        case .missingAPIKey:
            return "Set REVADDR_API_KEY to your RevAddr API key."
        case .http(let code, let body):
            return "HTTP \(code): \(body)"
        case .badURL:
            return "Could not build request URL"
        }
    }
}

/// GET /v1/reverse and decode the {"result": ...} envelope.
func reverseGeocode(
    lat: Double,
    lon: Double,
    apiKey: String,
    baseURL: String = defaultBase
) async throws -> ReverseResult {
    let root = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
    guard var components = URLComponents(string: "\(root)/v1/reverse") else {
        throw RevAddrError.badURL
    }
    // Query items encode lat/lon safely.
    components.queryItems = [
        URLQueryItem(name: "lat", value: String(lat)),
        URLQueryItem(name: "lon", value: String(lon)),
    ]
    guard let url = components.url else { throw RevAddrError.badURL }

    var request = URLRequest(url: url, timeoutInterval: 30)
    // Auth header required on every reverse call.
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)
    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
    if code < 200 || code >= 300 {
        let body = String(data: data, encoding: .utf8) ?? ""
        throw RevAddrError.http(code, body)
    }
    return try JSONDecoder().decode(ReverseEnvelope.self, from: data).result
}

// --- CLI entry (script-friendly; uses a semaphore so `swift main.swift` works) ---

guard let apiKey = ProcessInfo.processInfo.environment["REVADDR_API_KEY"]?
    .trimmingCharacters(in: .whitespacesAndNewlines),
    !apiKey.isEmpty
else {
    fputs(RevAddrError.missingAPIKey.description + "\n", stderr)
    exit(1)
}

let baseEnv = ProcessInfo.processInfo.environment["REVADDR_BASE_URL"]?
    .trimmingCharacters(in: .whitespacesAndNewlines)
let baseURL = (baseEnv?.isEmpty == false) ? baseEnv! : defaultBase

let args = CommandLine.arguments
// Website hero default: White House.
var lat = 38.8977
var lon = -77.0365
if args.count >= 3 {
    guard let a = Double(args[1]), let b = Double(args[2]) else {
        fputs("Usage: swift main.swift [lat lon]\n", stderr)
        exit(2)
    }
    lat = a
    lon = b
}

let sem = DispatchSemaphore(value: 0)
var cliError: Error?
var cliResult: ReverseResult?

Task {
    do {
        cliResult = try await reverseGeocode(
            lat: lat, lon: lon, apiKey: apiKey, baseURL: baseURL)
    } catch {
        cliError = error
    }
    sem.signal()
}
sem.wait()

if let cliError {
    fputs("\(cliError)\n", stderr)
    exit(1)
}

guard let result = cliResult else {
    fputs("No result\n", stderr)
    exit(1)
}

print(result.formattedAddress ?? "(no formatted_address)")

var dict: [String: Any] = [:]
if let v = result.formattedAddress { dict["formatted_address"] = v }
if let v = result.houseNumber { dict["house_number"] = v }
if let v = result.street { dict["street"] = v }
if let v = result.city { dict["city"] = v }
if let v = result.state { dict["state"] = v }
if let v = result.postcode { dict["postcode"] = v }
if let v = result.county { dict["county"] = v }
if let v = result.matchType { dict["match_type"] = v }
if let v = result.confidence { dict["confidence"] = v }
if let v = result.distanceMeters { dict["distance_meters"] = v }
if let v = result.lat { dict["lat"] = v }
if let v = result.lon { dict["lon"] = v }

if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
   let s = String(data: data, encoding: .utf8) {
    print(s)
}
