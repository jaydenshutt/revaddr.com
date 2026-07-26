# Elixir sample

```bash
export REVADDR_API_KEY="sk_live_..."
mix deps.get
mix run -e 'Revaddr.Reverse.main([])'
mix run -e 'Revaddr.Reverse.main(["37.7749", "-122.4194"])'
```

Use `Revaddr.Reverse.reverse/3` from a Phoenix controller or background worker. Keep the API key in runtime config / secrets, not in source.
