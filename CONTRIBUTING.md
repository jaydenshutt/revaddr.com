# Contributing

Thanks for helping engineers reverse-geocode with RevAddr.

## Guidelines

1. **No secrets.** Never commit API keys, `.env`, or production credentials.
2. **Match the public API.** Use `x-api-key`, `GET /v1/reverse`, and the `{"result":...}` envelope.
3. **Keep samples runnable.** Document run commands in a short README next to new languages.
4. **Env-based config.** Read `REVADDR_API_KEY` and optional `REVADDR_BASE_URL`.
5. **Comments over cleverness.** Explain auth, timeouts, and quality fields for newcomers.
6. **No em dashes** in user-facing docs or sample comments (project style).

## Suggesting a language

Open a PR with:

- `examples/<lang>/` sample that reverse-geocodes the White House by default
- CLI args for optional lat/lon
- HTTP error handling
- A one-screen README with install/run steps
