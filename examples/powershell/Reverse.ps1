<#
.SYNOPSIS
  Reverse-geocode a lat/lon with the RevAddr API (PowerShell 5.1+ / 7+).

.DESCRIPTION
  Calls GET /v1/reverse with the x-api-key header and prints formatted_address
  plus the full result object. Designed for Windows automation and ops scripts.

.EXAMPLE
  $env:REVADDR_API_KEY = "sk_live_..."
  .\Reverse.ps1

.EXAMPLE
  .\Reverse.ps1 -Lat 37.7749 -Lon -122.4194
#>

[CmdletBinding()]
param(
    [double]$Lat = 38.8977,
    [double]$Lon = -77.0365,
    [string]$BaseUrl = $(if ($env:REVADDR_BASE_URL) { $env:REVADDR_BASE_URL } else { "https://api.revaddr.com" })
)

$ErrorActionPreference = "Stop"

$apiKey = $env:REVADDR_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Error "Set REVADDR_API_KEY to your RevAddr API key. Get one at https://revaddr.com/create-account.html"
}

$BaseUrl = $BaseUrl.TrimEnd("/")
# Build URI with culture-invariant decimals (PowerShell can localize commas otherwise).
$latS = $Lat.ToString([System.Globalization.CultureInfo]::InvariantCulture)
$lonS = $Lon.ToString([System.Globalization.CultureInfo]::InvariantCulture)
$uri = "$BaseUrl/v1/reverse?lat=$latS&lon=$lonS"

# Headers: auth + JSON accept. Do not put the key in the query string.
$headers = @{
    "x-api-key" = $apiKey
    "Accept"    = "application/json"
}

try {
    # -TimeoutSec prevents hung sockets in automation.
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -TimeoutSec 30
}
catch {
    Write-Error "RevAddr request failed: $_"
}

if (-not $response.result) {
    Write-Error "Unexpected response shape (missing result)."
}

$result = $response.result
if ($result.formatted_address) {
    Write-Output $result.formatted_address
}
else {
    Write-Output "(no formatted_address)"
}

# Pretty-print structured fields for operators debugging match quality.
$result | ConvertTo-Json -Depth 6
