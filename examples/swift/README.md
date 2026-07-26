# Swift sample

Async reverse-geocode using `URLSession` and `Codable`.

```bash
export REVADDR_API_KEY="sk_live_..."
swift main.swift
swift main.swift 37.7749 -122.4194
```

**iOS tip:** Prefer calling RevAddr from your backend so the API key is not embedded in the app. If you must call from the client, store the key in the Keychain and rotate it if the binary leaks.
