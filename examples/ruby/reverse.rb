#!/usr/bin/env ruby
# frozen_string_literal: true

# Reverse-geocode a single point with RevAddr (Ruby 3+, stdlib net/http).
#
# Run:
#   export REVADDR_API_KEY=sk_live_...
#   ruby reverse.rb
#   ruby reverse.rb 37.7749 -122.4194

require "json"
require "net/http"
require "uri"

DEFAULT_BASE = "https://api.revaddr.com"

api_key = ENV.fetch("REVADDR_API_KEY", "").strip
if api_key.empty?
  warn "Set REVADDR_API_KEY to your RevAddr API key."
  exit 1
end

base = ENV.fetch("REVADDR_BASE_URL", DEFAULT_BASE).strip
base = base.sub(%r{/\z}, "")

# Defaults match the public website example.
lat = ARGV[0] ? Float(ARGV[0]) : 38.8977
lon = ARGV[1] ? Float(ARGV[1]) : -77.0365

# URI encodes query parameters; path is fixed to the reverse endpoint.
uri = URI("#{base}/v1/reverse")
uri.query = URI.encode_www_form("lat" => lat, "lon" => lon)

# Net::HTTP with open/read timeouts so hung sockets fail fast.
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = (uri.scheme == "https")
http.open_timeout = 5
http.read_timeout = 30

request = Net::HTTP::Get.new(uri)
request["x-api-key"] = api_key
request["Accept"] = "application/json"

response = http.request(request)
unless response.is_a?(Net::HTTPSuccess)
  warn "HTTP #{response.code}: #{response.body}"
  exit 1
end

payload = JSON.parse(response.body)
result = payload.fetch("result")
puts(result["formatted_address"] || "(no formatted_address)")
puts JSON.pretty_generate(result)
