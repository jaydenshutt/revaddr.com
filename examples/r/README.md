# R samples

```r
install.packages(c("httr", "jsonlite"))
```

```bash
export REVADDR_API_KEY="sk_live_..."
Rscript reverse.R
Rscript batch.R
```

For large tables, split into chunks of at most 100 points, call `batch.R` logic, and bind rows. Always keep `match_type` and `distance_meters` for QA filters in analytical pipelines.
