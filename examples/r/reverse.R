#!/usr/bin/env Rscript
# Reverse-geocode a single lat/lon with RevAddr (R).
#
# Install once:
#   install.packages(c("httr", "jsonlite"))
#
# Run:
#   export REVADDR_API_KEY=sk_live_...
#   Rscript reverse.R
#   Rscript reverse.R 37.7749 -122.4194
#
# For data frames, see batch.R (vectorized backfills).

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
if (!nzchar(api_key)) {
  stop("Set REVADDR_API_KEY to your RevAddr API key.", call. = FALSE)
}

base_url <- Sys.getenv("REVADDR_BASE_URL", unset = default_base)
base_url <- sub("/$", "", base_url)

args <- commandArgs(trailingOnly = TRUE)
# Website hero default (White House).
lat <- if (length(args) >= 1) as.numeric(args[[1]]) else 38.8977
lon <- if (length(args) >= 2) as.numeric(args[[2]]) else -77.0365

# GET /v1/reverse with auth header; httr encodes query params.
resp <- GET(
  paste0(base_url, "/v1/reverse"),
  query = list(lat = lat, lon = lon),
  add_headers(`x-api-key` = api_key, Accept = "application/json"),
  timeout(30)
)

if (http_error(resp)) {
  stop(sprintf("HTTP %s: %s", status_code(resp), content(resp, "text", encoding = "UTF-8")),
       call. = FALSE)
}

payload <- content(resp, as = "parsed", type = "application/json")
result <- payload$result
if (is.null(result)) {
  stop("Unexpected response shape (missing result).", call. = FALSE)
}

# Primary display line for logs / reports.
cat(if (!is.null(result$formatted_address)) result$formatted_address else "(no formatted_address)",
    "\n", sep = "")
cat(toJSON(result, auto_unbox = TRUE, pretty = TRUE), "\n", sep = "")
