/*
 * Reverse-geocode with RevAddr using libcurl (C99).
 *
 * Build:
 *   make
 *   export REVADDR_API_KEY=sk_live_...
 *   ./reverse
 *   ./reverse 37.7749 -122.4194
 *
 * Allocates a growable buffer for the response body, then prints it.
 */

#include <curl/curl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct mem {
  char *data;
  size_t len;
};

/* Append downloaded chunk; return 0 on OOM so libcurl aborts cleanly. */
static size_t write_cb(char *ptr, size_t size, size_t nmemb, void *userdata) {
  size_t total = size * nmemb;
  struct mem *m = (struct mem *)userdata;
  char *p = realloc(m->data, m->len + total + 1);
  if (!p) {
    return 0;
  }
  m->data = p;
  memcpy(m->data + m->len, ptr, total);
  m->len += total;
  m->data[m->len] = '\0';
  return total;
}

int main(int argc, char **argv) {
  const char *api_key = getenv("REVADDR_API_KEY");
  if (!api_key || !api_key[0]) {
    fprintf(stderr, "Set REVADDR_API_KEY to your RevAddr API key.\n");
    return 1;
  }

  const char *base_env = getenv("REVADDR_BASE_URL");
  const char *base =
      (base_env && base_env[0]) ? base_env : "https://api.revaddr.com";

  double lat = 38.8977;
  double lon = -77.0365;
  if (argc >= 3) {
    lat = atof(argv[1]);
    lon = atof(argv[2]);
  }

  char url[512];
  /* snprintf bounds the URL buffer; base is operator-controlled, lat/lon are numbers. */
  if (snprintf(url, sizeof(url), "%s/v1/reverse?lat=%.6f&lon=%.6f", base, lat,
               lon) >= (int)sizeof(url)) {
    fprintf(stderr, "URL too long\n");
    return 1;
  }

  CURL *curl = curl_easy_init();
  if (!curl) {
    fprintf(stderr, "curl_easy_init failed\n");
    return 1;
  }

  struct mem chunk = {0};
  char auth[256];
  if (snprintf(auth, sizeof(auth), "x-api-key: %s", api_key) >= (int)sizeof(auth)) {
    fprintf(stderr, "API key too long for header buffer\n");
    curl_easy_cleanup(curl);
    return 1;
  }

  struct curl_slist *headers = NULL;
  headers = curl_slist_append(headers, auth);
  headers = curl_slist_append(headers, "Accept: application/json");

  curl_easy_setopt(curl, CURLOPT_URL, url);
  curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &chunk);
  curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);

  CURLcode rc = curl_easy_perform(curl);
  long http_code = 0;
  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

  if (rc != CURLE_OK) {
    fprintf(stderr, "curl error: %s\n", curl_easy_strerror(rc));
  } else if (http_code < 200 || http_code >= 300) {
    fprintf(stderr, "HTTP %ld: %s\n", http_code,
            chunk.data ? chunk.data : "");
    rc = CURLE_HTTP_RETURNED_ERROR;
  } else {
    printf("%s\n", chunk.data ? chunk.data : "");
  }

  free(chunk.data);
  curl_slist_free_all(headers);
  curl_easy_cleanup(curl);
  return rc == CURLE_OK ? 0 : 1;
}
