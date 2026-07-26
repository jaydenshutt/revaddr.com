// Reverse-geocode with RevAddr using libcurl (C++17).
//
// Build (requires libcurl):
//   make
//   export REVADDR_API_KEY=sk_live_...
//   ./reverse
//   ./reverse 37.7749 -122.4194
//
// Flow: set URL + x-api-key header, perform GET, print response body.

#include <curl/curl.h>

#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>

// libcurl write callback: append downloaded bytes into a std::string.
static size_t write_cb(char* ptr, size_t size, size_t nmemb, void* userdata) {
  auto* out = static_cast<std::string*>(userdata);
  out->append(ptr, size * nmemb);
  return size * nmemb;
}

int main(int argc, char** argv) {
  const char* api_key = std::getenv("REVADDR_API_KEY");
  if (!api_key || !*api_key) {
    std::cerr << "Set REVADDR_API_KEY to your RevAddr API key.\n";
    return 1;
  }

  const char* base_env = std::getenv("REVADDR_BASE_URL");
  std::string base = (base_env && *base_env) ? base_env : "https://api.revaddr.com";
  while (!base.empty() && base.back() == '/') {
    base.pop_back();
  }

  // White House default (website example).
  double lat = 38.8977;
  double lon = -77.0365;
  if (argc >= 3) {
    lat = std::stod(argv[1]);
    lon = std::stod(argv[2]);
  }

  std::ostringstream url;
  url << base << "/v1/reverse?lat=" << lat << "&lon=" << lon;

  CURL* curl = curl_easy_init();
  if (!curl) {
    std::cerr << "curl_easy_init failed\n";
    return 1;
  }

  std::string body;
  // Header list must stay alive until curl_easy_perform returns.
  std::string auth = std::string("x-api-key: ") + api_key;
  struct curl_slist* headers = nullptr;
  headers = curl_slist_append(headers, auth.c_str());
  headers = curl_slist_append(headers, "Accept: application/json");

  curl_easy_setopt(curl, CURLOPT_URL, url.str().c_str());
  curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &body);
  curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
  // Follow redirects if the edge terminates TLS with a redirect (usually not needed).
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);

  CURLcode rc = curl_easy_perform(curl);
  long http_code = 0;
  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

  curl_slist_free_all(headers);
  curl_easy_cleanup(curl);

  if (rc != CURLE_OK) {
    std::cerr << "curl error: " << curl_easy_strerror(rc) << "\n";
    return 1;
  }
  if (http_code < 200 || http_code >= 300) {
    std::cerr << "HTTP " << http_code << ": " << body << "\n";
    return 1;
  }

  // Body is {"result":{...}}; parse with your preferred JSON library in production.
  std::cout << body << "\n";
  return 0;
}
