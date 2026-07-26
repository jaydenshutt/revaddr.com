#!/usr/bin/env Rscript
# Batch reverse-geocode (POST /v1/reverse/batch) for R analytics workflows.
#
# Install: install.packages(c("httr", "jsonlite"))
# Run:     export REVADDR_API_KEY=sk_live_... ; Rscript batch.R
#
# Tip: chunk data frames into groups of <= 100 rows and rbind results.

suppressPackageStartupMessages({
  if (!requireNamespace("httr", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Install packages: install.packages(c(\"httr\", \"jsonlite\"))", call. = FALSE)
  }
  library(httr)
  library(jsonlite)
})

default_base <- "https://api.revaddr.com"
api_key <- Sys.getenv("REVADDR_API_KEY", unset = "")
if (!nzchar(api_key)) stop("Set REVADDR_API_KEY.", call. = FALSE)

base_url <- sub("/$", "", Sys.getenv("REVADDR_BASE_URL", unset = default_base))

points <- list(
  list(lat = 38.8977, lon = -77.0365),
  list(lat = 37.7749, lon = -122.4194),
  list(lat = 40.7128, lon = -74.0060)
)

# Body shape required by the API.
body <- list(points = points)

resp <- POST(
  paste0(base_url, "/v1/reverse/batch"),
  body = body,
  encode = "json",
  add_headers(`x-api-key` = api_key, Accept = "application/json"),
  timeout(60)
)

if (http_error(resp)) {
  stop(sprintf("HTTP %s: %s", status_code(resp), content(resp, "text", encoding = "UTF-8")),
       call. = FALSE)
}

payload <- content(resp, as = "parsed", type = "application/json")
results <- payload$results
if (is.null(results)) stop("Unexpected response (missing results).", call. = FALSE)

for (i in seq_along(results)) {
  p <- points[[i]]
  addr <- results[[i]]$formatted_address
  if (is.null(addr)) addr <- "(none)"
  cat(sprintf("[%d] (%s, %s) -> %s\n", i - 1L, p$lat, p$lon, addr))
}

cat(toJSON(results, auto_unbox = TRUE, pretty = TRUE), "\n", sep = "")
