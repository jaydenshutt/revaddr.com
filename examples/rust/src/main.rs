//! Reverse-geocode a single lat/lon with the RevAddr API (Rust).
//!
//! Run:
//! ```text
//! export REVADDR_API_KEY=sk_live_...
//! cargo run
//! cargo run -- 37.7749 -122.4194
//! ```
//!
//! Uses blocking reqwest for a short CLI sample. Async works the same with
//! `.await` on the request builder.

use serde::{Deserialize, Serialize};
use std::env;
use std::process;

const DEFAULT_BASE: &str = "https://api.revaddr.com";

/// Inner object under `"result"`.
#[derive(Debug, Deserialize, Serialize)]
struct ReverseResult {
    formatted_address: Option<String>,
    house_number: Option<String>,
    street: Option<String>,
    city: Option<String>,
    state: Option<String>,
    postcode: Option<String>,
    county: Option<String>,
    match_type: Option<String>,
    confidence: Option<f64>,
    distance_meters: Option<f64>,
    lat: Option<f64>,
    lon: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct ReverseEnvelope {
    result: ReverseResult,
}

fn reverse(lat: f64, lon: f64, api_key: &str, base_url: &str) -> Result<ReverseResult, String> {
    let base = base_url.trim_end_matches('/');
    // Query params via reqwest (percent-encoding handled for us).
    let url = format!("{base}/v1/reverse");

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| e.to_string())?;

    let response = client
        .get(&url)
        .header("x-api-key", api_key)
        .header("Accept", "application/json")
        .query(&[("lat", lat), ("lon", lon)])
        .send()
        .map_err(|e| e.to_string())?;

    let status = response.status();
    let body = response.text().map_err(|e| e.to_string())?;
    if !status.is_success() {
        return Err(format!("HTTP {status}: {body}"));
    }

    let envelope: ReverseEnvelope =
        serde_json::from_str(&body).map_err(|e| format!("JSON parse: {e}; body={body}"))?;
    Ok(envelope.result)
}

fn main() {
    let api_key = env::var("REVADDR_API_KEY").unwrap_or_default();
    if api_key.trim().is_empty() {
        eprintln!("Set REVADDR_API_KEY to your RevAddr API key.");
        process::exit(1);
    }

    let base_url = env::var("REVADDR_BASE_URL").unwrap_or_else(|_| DEFAULT_BASE.to_string());

    // CLI args optional; defaults match website hero (White House).
    let mut lat = 38.8977_f64;
    let mut lon = -77.0365_f64;
    let args: Vec<String> = env::args().skip(1).collect();
    if args.len() >= 2 {
        lat = args[0].parse().unwrap_or_else(|_| {
            eprintln!("invalid lat");
            process::exit(2);
        });
        lon = args[1].parse().unwrap_or_else(|_| {
            eprintln!("invalid lon");
            process::exit(2);
        });
    }

    match reverse(lat, lon, api_key.trim(), &base_url) {
        Ok(result) => {
            println!(
                "{}",
                result
                    .formatted_address
                    .as_deref()
                    .unwrap_or("(no formatted_address)")
            );
            println!("{}", serde_json::to_string_pretty(&result).unwrap());
        }
        Err(e) => {
            eprintln!("{e}");
            process::exit(1);
        }
    }
}
