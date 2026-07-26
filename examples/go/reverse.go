// Reverse-geocode one lat/lon with the RevAddr API (Go stdlib only).
//
// Run:
//
//	export REVADDR_API_KEY=sk_live_...
//	go run .
//	go run . 37.7749 -122.4194
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"time"
)

const defaultBase = "https://api.revaddr.com"

// reverseResult mirrors the JSON object under "result".
// Only fields we use are declared; extra JSON keys are ignored.
type reverseResult struct {
	FormattedAddress string  `json:"formatted_address"`
	HouseNumber      string  `json:"house_number"`
	Street           string  `json:"street"`
	City             string  `json:"city"`
	State            string  `json:"state"`
	Postcode         string  `json:"postcode"`
	County           string  `json:"county"`
	MatchType        string  `json:"match_type"`
	Confidence       float64 `json:"confidence"`
	DistanceMeters   float64 `json:"distance_meters"`
	Lat              float64 `json:"lat"`
	Lon              float64 `json:"lon"`
}

type reverseEnvelope struct {
	Result reverseResult `json:"result"`
}

func reverse(lat, lon float64, apiKey, baseURL string) (reverseResult, error) {
	// Build query string with proper encoding.
	q := url.Values{}
	q.Set("lat", strconv.FormatFloat(lat, 'f', -1, 64))
	q.Set("lon", strconv.FormatFloat(lon, 'f', -1, 64))

	endpoint := baseURL + "/v1/reverse?" + q.Encode()
	req, err := http.NewRequest(http.MethodGet, endpoint, nil)
	if err != nil {
		return reverseResult{}, err
	}
	// Auth header name is fixed by the API: x-api-key
	req.Header.Set("x-api-key", apiKey)
	req.Header.Set("Accept", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	res, err := client.Do(req)
	if err != nil {
		return reverseResult{}, err
	}
	defer res.Body.Close()

	body, err := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	if err != nil {
		return reverseResult{}, err
	}
	if res.StatusCode != http.StatusOK {
		return reverseResult{}, fmt.Errorf("HTTP %d: %s", res.StatusCode, body)
	}

	var payload reverseEnvelope
	if err := json.Unmarshal(body, &payload); err != nil {
		return reverseResult{}, err
	}
	return payload.Result, nil
}

func main() {
	apiKey := os.Getenv("REVADDR_API_KEY")
	if apiKey == "" {
		fmt.Fprintln(os.Stderr, "Set REVADDR_API_KEY to your RevAddr API key.")
		os.Exit(1)
	}
	baseURL := os.Getenv("REVADDR_BASE_URL")
	if baseURL == "" {
		baseURL = defaultBase
	}

	// Defaults match the public website example (White House).
	lat, lon := 38.8977, -77.0365
	if len(os.Args) >= 3 {
		var err error
		lat, err = strconv.ParseFloat(os.Args[1], 64)
		if err != nil {
			fmt.Fprintln(os.Stderr, "invalid lat")
			os.Exit(2)
		}
		lon, err = strconv.ParseFloat(os.Args[2], 64)
		if err != nil {
			fmt.Fprintln(os.Stderr, "invalid lon")
			os.Exit(2)
		}
	}

	result, err := reverse(lat, lon, apiKey, baseURL)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	fmt.Println(result.FormattedAddress)
	out, _ := json.MarshalIndent(result, "", "  ")
	fmt.Println(string(out))
}
