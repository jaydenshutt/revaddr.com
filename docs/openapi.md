# OpenAPI

RevAddr publishes interactive OpenAPI documentation from the live API:

| Resource | URL |
|----------|-----|
| Swagger UI | https://api.revaddr.com/docs |
| ReDoc (if enabled on host) | https://api.revaddr.com/redoc |
| OpenAPI schema | https://api.revaddr.com/openapi.json |

## What integrators should use

Public integrator paths (API key required unless noted):

- `GET /v1/reverse`
- `POST /v1/reverse`
- `POST /v1/reverse/batch`
- `GET /v1/usage`
- `GET /v1/meta` (public product meta)

Signup / email verify / account portal endpoints exist for the product website; prefer the hosted UI at https://revaddr.com unless you are building a custom onboarding flow.

Load-balancer and internal ops probes are **not** part of the public integrator contract (not documented here or in the samples).

## Codegen tip

```bash
# Example: generate a TypeScript fetch client (requires openapi-generator-cli)
openapi-generator-cli generate \
  -i https://api.revaddr.com/openapi.json \
  -g typescript-fetch \
  -o ./generated/typescript
```

Generated clients still need you to set the `x-api-key` header. Prefer the hand-written samples under `examples/` when learning the API; use codegen for large internal monorepos.
