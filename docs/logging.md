# Structured Logging

This template includes a minimal structured logging baseline with two paths:

1. HTTP request logs via Lograge.
2. Application event logs via `AppEvent`.

Both emit JSON with a shared envelope style to keep downstream log processing simple.

## Request Logging (Lograge)

Production enables and configures Lograge in:

- `config/environments/production.rb`

The custom options builder lives in `lib/logging/structured_request_log.rb`. See this file for the full payload shape and enrichment.

## Payload Enrichment

Request context is intentionally isolated by auth surface to avoid helper conflicts between Devise session flows and DeviseTokenAuth token flows.

`ApplicationController` does not append actor data bc Deivse and DTA helper methods conflicted (or not existed) at that level. Logging enrichment success depended on route and auth surface so that was moved to the scoped controllers where the actor model is known.

Actor enrichment is defined only where the actor model is known:

- `app/controllers/api/base_controller.rb`
  - Adds `user_id` and `visitor_token` for `/api/*` token-auth API requests.
- `app/controllers/auth/sessions_controller.rb`
- `app/controllers/auth/registrations_controller.rb`
- `app/controllers/auth/passwords_controller.rb`
  - Add `user_id` for `/auth/*` DeviseTokenAuth endpoints.
- `app/controllers/admins/sessions_controller.rb`
- `app/controllers/admins/passwords_controller.rb`
  - Add `admin_id` for `/admins/*` Devise session endpoints.

Why this split exists:

- Trying to enrich actor data globally in `ApplicationController` caused DeviseTokenAuth helper chains to be evaluated in requests outside their intended scope.
- In practice this meant auth helpers like `current_admin`/`current_user` could leak across call chains and break request logging.
- Confining enrichment to scoped controllers keeps Devise and DeviseTokenAuth paths independent and predictable.

Note: `request_id` and `remote_ip` are available from Rails `process_action` payload/request objects by default and do not need manual payload enrichment.

## Application Logging (AppEvent)

`AppEvent` is a tiny wrapper around `Rails.logger`:

- `lib/app_event.rb`

Methods:

- `AppEvent.info(event_name, **payload)`
- `AppEvent.warn(event_name, **payload)`
- `AppEvent.error(event_name, **payload)`

Example:

```rb
AppEvent.info("user.signup", user_id: user.id, plan: "pro")
```

Output shape:

```json
{
  "timestamp": "2026-06-28T12:00:00.000Z",
  "severity": "INFO",
  "event": "user.signup",
  "user_id": 42,
  "plan": "pro"
}
```

## Design Notes

- Request logging is automatic in production via Lograge.
- `AppEvent` is optional and explicit at call sites.
- `AppEvent` intentionally contains no hidden request context, subscriber wiring, or event bus behavior.
- If logging backends change later, update `lib/app_event.rb` without changing application call sites.
