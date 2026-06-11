# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## CORS

This template enables CORS with `rack-cors`.

- Set `CORS_ALLOWED_ORIGINS` to a comma-separated list of allowed origins.
- Cors are set in env specific config/environments/*.rb files

## Basic Rate Limiting (Rack::Attack)

This template uses `rack-attack` to throttle sensitive and write-heavy endpoints.

Configured throttles live in `config/initializers/rack_attack.rb`.

Current throttled routes (by request IP):

- `POST /auth/sign_in`
- `POST /auth`
- `POST|PUT|PATCH|DELETE /api/v1/users*`

Default limits:

- Auth sign in: `10` requests / `60` seconds
- Auth sign up: `10` requests / `60` seconds
- Users write endpoints: `15` requests / `60` seconds

Environment variables:

- `THROTTLE_AUTH_SIGN_IN_LIMIT`
- `THROTTLE_AUTH_SIGN_IN_PERIOD`
- `THROTTLE_AUTH_SIGN_UP_LIMIT`
- `THROTTLE_AUTH_SIGN_UP_PERIOD`
- `THROTTLE_USERS_WRITE_LIMIT`
- `THROTTLE_USERS_WRITE_PERIOD`

When a request is throttled, Rack::Attack returns `429 Too Many Requests` using its default response behavior.

## API Versioning

API endpoints should be added under `/api/v1`.

The `/api/` namespace defaults to JSON responses.

- Canonical hello endpoint: `GET /api/v1/hello`

## API Docs (ReDoc)

This template includes a lightweight ReDoc UI backed by the OpenAPI document.
These are unprotected in dev environment for easy access and admin auth'ed in production by default.

- ReDoc UI: `GET /api/docs`
- OpenAPI YAML: `GET /api/openapi.yml`

The source OpenAPI file lives at `docs/openapi.yml`.

## Database Observability (PgHero)

PgHero is mounted for basic query/index visibility at:

- `GET /pghero`

Access behavior:

- `development`: route is available without auth for local debugging.
- non-development (`test`/`production`): route is mounted only for authenticated admin users via Devise session auth.

To access in non-development, sign in through session auth first:

- `GET /users/sign_in`

## Authentication Flows

This app supports two different authentication styles at the same time:

- Token auth for JSON API clients (mobile/SPA) via Devise Token Auth.
- Cookie session auth for browser-based admin-only routes via Devise sessions.

They intentionally use different URL paths so they do not conflict:

- Token auth endpoints: `/auth/*`
- Session auth endpoints: `/users/*`

### API token auth flow (`/auth/*`)

Route mount:

- `mount_devise_token_auth_for "User", at: "auth", as: "token_auth_users"`

Main endpoints:

- `POST /auth` (registration)
- `POST /auth/sign_in` (token login)
- `DELETE /auth/sign_out` (token logout)
- `GET /auth/validate_token`

Token login response headers (used on subsequent API requests):

- `access-token`
- `client`
- `uid`
- `expiry`
- `token-type`

Typical API client flow:

1. `POST /auth/sign_in` with email/password.
2. Store response token headers on the client.
3. Send those headers with each protected API call (for example `GET /api/v1/users/me`).
4. Rotate stored token values from response headers when returned.

### Admin/browser session auth flow (`/users/*`)

Route mount:

- `devise_for :users, only: [ :sessions ]`

Main endpoints:

- `GET /users/sign_in`
- `POST /users/sign_in`
- `DELETE /users/sign_out`

Use this flow for browser-only/admin-only routes that rely on cookie sessions.

Recommended pattern for admin routes:

1. Require an authenticated Devise session (`authenticate_user!`).
2. Require admin role (`current_user.admin?`).
3. Return `403 forbidden` (or redirect for HTML pages) when non-admin users attempt access.

Minimal controller gate example:

```rb
before_action :authenticate_user!
before_action :require_admin!

private

def require_admin!
	return if current_user&.admin?

	head :forbidden
end
```

For route-level constraints, use the same logic (authenticated user + `admin?`) before mounting admin-only endpoints.

## Service Object Layer (SVC)

This template uses a service-object layer under `app/services/svc`.

- Controllers should stay thin and delegate business logic to service objects.
- Service objects should expose a single entrypoint via `.call`.
- Place shared behavior in `Svc::Base`.
- Group services by domain/version (for example `Svc::Api::V1::Hello::Show`).
- Service objects in this app are Rails-aware by design.

Rails-awareness:

- It is acceptable for service objects to use Rails primitives directly (for example `Rails.cache`, `ActiveRecord`, `ActiveSupport`, models, etc...).
- Do not pass dependency inject things like `Rails.cache`, request objects, or controller instances into services unless there is a strong reason.

Usage conventions:

- Keep domain behavior, orchestration, and reusable rules in SVC objects.
- Return plain Ruby hashes/values from services for easy composition and testing.
- Raise meaningful exceptions from services and let controller-level error handling render API error envelopes.
- Unit test services directly under `test/services`, and keep integration tests focused on endpoint behavior.
- Svc naming and namespacing does not necessarily need to mirror controller structure and controller action names, but should be organized in a way that is easy to find and understand.

Example flow:

- Controller: `Api::V1::HelloController#show`
- Service object: `Svc::Api::V1::Hello::Show`

## API Error Handling

This template uses a common gem-style JSON error envelope.

```json
{
	"success": false,
	"errors": [
		"param is missing or the value is empty: widget"
	],
	"error_type": "bad_request",
	"request_id": "9a9de824-fdb2-4f57-9525-c3fd2930a34d"
}
```

The `request_id` value matches Rails request logging and can be used for tracing.

When details are provided (for example validation failures), they are appended to the `errors` array.

Default exception mapping:

- `ActionController::ParameterMissing` -> `400 bad_request`
- `ActionController::BadRequest` -> `400 bad_request`
- `ActiveRecord::RecordNotFound` -> `404 not_found`
- `ActiveRecord::RecordInvalid` -> `422 unprocessable_entity` (includes validation messages in `errors`)
- `ActiveRecord::RecordNotSaved` -> `422 unprocessable_entity`
- `StandardError` -> `500 internal_server_error`

This format is aligned with authentication error responses from `devise_token_auth`.

## API Input Validation (Contracts)

API input are validated with contract objects under `app/contracts`.

Pattern:

- Controllers build and validate API inputes with a contract before calling a service object.
- Contracts raise `ApplicationContract::Invalid` when invalid, which is handled by normal API error handling flow.

## API Serialization (Blueprinter)

This template uses `blueprinter` as the single approach for API success-response serialization.

- Controller helper: `render_serialized(blueprint, payload, status: :ok)` in `Api::V1::BaseController`

Conventions:

- Controllers should render API success responses through Blueprinter, not ad hoc hashes.
- Shared response metadata (for example `request_id`) is injected in the base controller before serialization.
- Endpoint blueprints define only fields that belong to the public API contract.

## Pagination / Collection Conventions (Pagy)

This template uses `pagy` for consistent collection endpoint pagination.

- See BaseController helpers
- Query params for collection endpoints:
	- `page` (default: `1`)
	- `per_page` (default: `25`, max: `100`)

## Authorization (Policies)

This template establishes where authorization decisions live, without predefining app-specific rules.

- Authentication answers: "Who is this?"
- Authorization answers: "Can they do this?"

Policy classes live in `app/policies`.

Defaults are deny-all to enforce explicit allow rules when real resources are added.

API controllers can call `authorize!(record, query = nil)` from `Api::V1::BaseController`.
- Authorization failures return a standard JSON error with `403 forbidden` through the normal API error handling flow.

## Local CI (Rails 8.1)

This project includes a local CI runner using Rails 8.1's `ActiveSupport::ContinuousIntegration`.

Run the full local pipeline:

```bash
bin/ci
```

The pipeline currently runs:

- Dependency check/install
- Test database prepare
- RuboCop
- Bundler Audit
- Brakeman
- FactoryBot lint
- Test suite
- Seed validation in test

Prerequisite: PostgreSQL must be running locally and accessible with your configured test DB settings.

Cheeck `config/ci.rb` for the full list of steps and commands run by the pipeline. You can also run individual steps manually.

## Single-DB Deployment (Solid Queue/Cache/Cable)

This template is configured to run all Solid components on the primary PostgreSQL database in production.

- `config/database.yml` uses a single `production` connection via `DATABASE_URL`.
- `config/environments/production.rb` points Solid Queue to `writing: :primary`.
- `config/cable.yml` points Solid Cable to `writing: primary`.
- `config/cache.yml` points Solid Cache to `database: primary`.

### Required environment variables

- `DATABASE_URL` (single managed Postgres database)
- `RAILS_MASTER_KEY`

### Process model

Use separate process types in production:

- `web`: Puma app server
- `job`: `bin/jobs` (Solid Queue worker/supervisor)

`SOLID_QUEUE_IN_PUMA` is set to `false` in deploy defaults to keep job execution isolated from web request latency.

### First deploy / release flow

Run standard Rails database tasks against the single database:

```bash
RAILS_ENV=production bin/rails db:prepare
RAILS_ENV=production bin/rails db:migrate
```

### Quick production smoke checks

```bash
RAILS_ENV=production bin/rails runner "puts Rails.application.config.active_job.queue_adapter"
RAILS_ENV=production bin/rails runner "Rails.cache.write('smoke','ok'); puts Rails.cache.read('smoke')"
```

## Open Source Template Security

This template is open source. Generated/default secrets must be replaced before deployment.

- Rotate Rails credentials and `secret_key_base`.
- Set your own `RAILS_MASTER_KEY` in secret management.
- Update mailer sender/SMTP credentials (`DEVISE_MAILER_SENDER` and provider secrets).
- Never commit production keys or credentials to version control.

