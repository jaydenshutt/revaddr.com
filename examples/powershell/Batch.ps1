<#
.SYNOPSIS
  Batch reverse-geocode with POST /v1/reverse/batch (max 100 points).

.EXAMPLE
  $env:REVADDR_API_KEY = "sk_live_..."
  .\Batch.ps1
#>

[CmdletBinding()]
param(
    [string]$BaseUrl = $(if ($env:REVADDR_BASE_URL) { $env:REVADDR_BASE_URL } else { "https://api.revaddr.com" })
)

$ErrorActionPreference = "Stop"

$apiKey = $env:REVADDR_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Error "Set REVADDR_API_KEY."
}

$BaseUrl = $BaseUrl.TrimEnd("/")
$uri = "$BaseUrl/v1/reverse/batch"

# Sample CONUS points (DC, San Francisco, NYC).
$bodyObj = @{
    points = @(
        @{ lat = 38.8977; lon = -77.0365 }
        @{ lat = 37.7749; lon = -122.4194 }
        @{ lat = 40.7128; lon = -74.0060 }
    )
}

$headers = @{
    "x-api-key"    = $apiKey
    "Content-Type" = "application/json"
    "Accept"       = "application/json"
}

$json = $bodyObj | ConvertTo-Json -Depth 5 -Compress
$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $json -TimeoutSec 60

if (-not $response.results) {
    Write-Error "Unexpected response shape (missing results)."
}

$i = 0
foreach ($r in $response.results) {
    $p = $bodyObj.points[$i]
    Write-Output ("[{0}] ({1}, {2}) -> {3}" -f $i, $p.lat, $p.lon, $r.formatted_address)
    $i++
}

$response.results | ConvertTo-Json -Depth 6
