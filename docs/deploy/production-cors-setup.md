# Production CORS Setup

This API template uses `rack-cors` and reads allowed origins from `CORS_ALLOWED_ORIGINS`.

Implementation references:

- [config/initializers/cors.rb](../../config/initializers/cors.rb)
- [config/environments/production.rb](../../config/environments/production.rb)

## Required Environment Variable

Set `CORS_ALLOWED_ORIGINS` in production as a comma-separated list of allowed frontend origins.

Example:

```bash
CORS_ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
```

Notes:

1. Include scheme (`https://`).
2. Do not include path segments.
3. Separate entries with commas.
4. Whitespace is tolerated and stripped by config parsing.

## Typical Deploy Checklist Item

Before first production deploy:

1. Decide the exact frontend origins that will call the API.
2. Set `CORS_ALLOWED_ORIGINS` in your production environment.
3. Deploy/restart app processes so env changes are loaded.
4. Verify preflight and request behavior from an allowed origin.

## Quick Verification

Replace values below with your real API URL and allowed frontend origin.

Preflight check:

```bash
curl -i -X OPTIONS "https://api.example.com/api/v1/users/me" \
  -H "Origin: https://app.example.com" \
  -H "Access-Control-Request-Method: GET"
```

Expected headers include:

- `Access-Control-Allow-Origin: https://app.example.com`
- `Vary: Origin`

Negative check (non-allowed origin):

```bash
curl -i -X OPTIONS "https://api.example.com/api/v1/users/me" \
  -H "Origin: https://not-allowed.example.com" \
  -H "Access-Control-Request-Method: GET"
```

Expected behavior:

1. No `Access-Control-Allow-Origin` header for the non-allowed origin.
