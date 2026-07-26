# TypeScript sample

Typed reverse + batch clients for Node 18+ (native `fetch`).

```bash
export REVADDR_API_KEY="sk_live_..."
npm install
npx tsx reverse.ts
npx tsx reverse.ts 37.7749 -122.4194
npx tsx batch.ts
```

Import `reverseGeocode` from `reverse.ts` into your service layer. Set the API key from environment or a secret manager.
