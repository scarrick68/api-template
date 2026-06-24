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

## Documentation Index

Operational and launch documentation lives in `docs/`.

- Documentation index: `docs/README.md`
- Production email setup: `docs/deploy/production-email-setup.md`
- Metrics model and observability pipeline: `docs/metrics-model.md`

## Authentication Architecture And Boundaries

This app intentionally separates API identity from internal operator identity.

- `User` is the app/API identity.
- `Admin` is the internal/operator identity.
- `Admin` has `belongs_to :user, optional: true`.

### Authentication mechanisms

- API requests use token auth via `devise_token_auth`.
- Internal/admin-only routes and mounted tools use Devise session auth.
- An admin session does not imply API token authentication.
- API token headers do not grant access to admin-only browser routes.

### Route boundaries

- `/api/v1/*` is JSON API surface and should use token auth with `current_user`.
- Admin/internal browser routes and mounted tools are session-protected (in non-development), including:
	- `/pghero`
	- `/blazer`
	- `/jobs`
	- `/flipper`
	- `/solid_errors`
	- `/field_test`
- API docs (`/docs`, `/openapi.yml`) are browser routes and are not part of the token-authenticated API surface.

### Controller boundaries

- `ApplicationController` should remain browser/session-safe and framework-level.
- `Api::BaseController` owns API-specific behavior:
	- Devise Token Auth integration
	- API authentication helpers and identity (`current_user`, `authenticate_user!`)
	- API error rendering
	- Ahoy/Field Test API participant identity wiring
- `Api::V1::BaseController` owns API v1 request concerns:
	- pagination
	- serialization
	- policy authorization
	- contract handling

### Auth helper conventions

- API controllers: use `current_user` and `authenticate_user!`.
- Admin/browser controllers: use `current_admin` and `authenticate_admin!` (or route-level `authenticate :admin` constraints for mounted engines).
- Current implementation note: `DocsController` uses `user_signed_in? && current_user.admin?` as its admin gate outside development.
- Keep session helper usage out of API controllers and token helper usage out of admin browser flows.

### Testing strategy

- API tests:
	- authenticate with token headers from `/auth/sign_in` (for example via `auth_headers_for(user)`).
	- verify token-authenticated requests can access API endpoints.
- Admin/browser and mounted tool tests:
	- authenticate with Devise session helpers (for example `sign_in admin` or the applicable session scope).
	- verify token-only requests are rejected or redirected for admin/session-only routes.
- Auth-boundary tests:
	- explicitly verify that token auth cannot access admin-only tools.
	- explicitly verify that admin session auth does not replace API token requirements.

### Attribution impact (Ahoy and Field Test)

- Frontend should own page/journey tracking.
- Backend Ahoy should capture server-confirmed business events.
- API attribution should rely on `current_user`/Ahoy identity so events and experiments stay consistent. This should largely be within the API domain where field_test is hooked into Ahoy identity and current_user. It can be used elsewhere, but attribution will not be automatic.
- Field Test participant identity uses Ahoy identity (`ahoy.user`, `ahoy.visitor_token`) so experiment assignment aligns with tracked API activity.

## Elasticsearch + Searchkick

This app uses Searchkick with Elasticsearch for model search.

Current config:

- Default URL: `http://localhost:9200`
- URL override: `ELASTICSEARCH_URL`

### Local setup

Elasticsearch is defined in `compose.yml` and can be started with:

```bash
docker compose up -d elasticsearch
```

`bin/dev` also starts Elasticsearch before starting the app processes.

### Verify Elasticsearch health

```bash
rails searchkick:health
```

You should see cluster status and version info if it's running and healthy.

### Test and CI notes

- See `test/test_helper.rb` for Searchkick test setup and configuration.
- Callbacks are disabled by default in tests, but can be enabled on a per-test basis when needed.

### Production placeholder

Configure your production env and creds as needed

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

## N+1 Detection (Bullet Gem)

This template includes the `bullet` gem in the `development, test` group.

For current environment configuration choices see:

- `config/environments/development.rb`:
- `config/environments/test.rb`:

Summary:

- Bullet is active in both development and test.
- In development, output is logger-based only (no browser alert/console/footer).
- In test, Bullet raises on detected N+1/unused eager loading issues.

## API Versioning

API endpoints should be added under `/api/v1`.

The `/api/` namespace defaults to JSON responses.

- Canonical authenticated user endpoint: `GET /api/v1/users/me`

## API Docs (ReDoc)

This template includes a lightweight ReDoc UI backed by the OpenAPI document.
Docs endpoints are always mounted, and access is enforced in the controller.

The source OpenAPI file lives at `docs/openapi.yml`.

Access behavior:

- `development`: docs are available without authentication.
- non-development (`test`/`production`): only authenticated admin Devise session users can access docs; all other requests receive `404 not found`.

## Database Observability (PgHero)

PgHero is mounted for basic query/index visibility at:

- `GET /pghero`

Access behavior:

- `development`: route is available without auth for local debugging.
- non-development (`test`/`production`): route is mounted only for authenticated admin users via Devise session auth.

To access in non-development, sign in through session auth first:

- `GET /admins/sign_in`

## Mission Control Jobs

Mission Control Jobs is mounted at:

- `GET /jobs`

Access behavior in this app:

- `development`: route is mounted directly.
- non-development (`test`/`production`): route is behind admin session auth via route constraints.

Mission Control Jobs also supports HTTP Basic Auth. Ensure environment-specific basic auth credentials are set and rotated per environment. Do not keep placeholder/default credentials in shared configs.

Future extension:

If you want Mission Control Jobs to use your app's admin controller stack directly, set:

```rb
MissionControl::Jobs.base_controller_class = "AdminController"
```

That lets Mission Control inherit auth/authorization behavior from your own admin controllers without needing to set basic auth credentials or use separate session auth.

## Analytics Tracking (Ahoy)

This template includes Ahoy for server-side event tracking.

Installed pieces:

- Gem: `ahoy_matey` (see `Gemfile`)
- Initializer: `config/initializers/ahoy.rb`
- Database tables: `ahoy_visits` and `ahoy_events`
- Models: `app/models/ahoy/visit.rb` and `app/models/ahoy/event.rb`

Current Ahoy config (`config/initializers/ahoy.rb`):

- `Ahoy.api = true`
- `Ahoy.geocode = false`
- `Ahoy.server_side_visits = :when_needed`

Basic controller usage:

```rb
ahoy.track "event.name", { key: "value" }
```

Test coverage:

- `test/integration/ahoy_tracking_test.rb` verifies that an Ahoy event is persisted.

## First-Party Observability (Metrics)

This template includes a built-in first-party observability pipeline based on the app-owned metrics table.

Detailed documentation for the metrics model, dry-schema contracts, API request fanout behavior, and Blazer dashboards now lives in docs/metrics-model.md.

## A/B Testing (Field Test)

This app includes Field Test scaffolding for experiments and conversion tracking.

Configured experiment definitions live in:

- `config/field_test.yml`

Dashboard route:

- `GET /field_test`

Route protection:

- `development`: mounted directly for local debugging.
- non-development (`test`/`production`): mounted behind admin session auth in routes.

Ahoy integration:

- `ApplicationController#field_test_participant` returns `[ahoy.user, ahoy.visitor_token]`.
- This makes Field Test participant identity reuse Ahoy's visitor token.

API status in this template:

- Field Test is installed and admin UI is mounted at `/field_test`.
- The template does **not** currently ship API endpoints to fetch or set experiment assignments.
- API contract and endpoint shape are intentionally TBD and should be designed alongside the frontend template.

Model wiring:

- `User` has `field_test_memberships` association via `FieldTest::Membership`.

## Feature Flags (Flipper)

This app uses a standard Flipper setup for feature flags. This is configured to be used first party, backed by the primary app DB. It does not use their cloud service.

Persistence:

- ActiveRecord-backed flag storage via `flipper_features` and `flipper_gates` tables.
- Tables are created by the Flipper migration in `db/migrate`.

UI route:

- `GET /flipper`

Route protection:

- `development`: mounted directly for local use.
- non-development (`test`/`production`): mounted behind admin session auth in routes.

Setup checklist:

1. Run migrations:

```bash
bin/rails db:migrate
```

2. In production/non-development, sign in as an admin user to access `/flipper`.

3. Installation verified with basic smoke tests

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

- `GET /admins/sign_in`
- `POST /admins/sign_in`
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
- Group services by domain/version (for example `Svc::Api::V1::Users::List`).
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

- Controller: `Api::V1::UsersController#index`
- Service object: `Svc::Api::V1::Users::List`

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

## Test Coverage

This app uses `SimpleCov` in `test/test_helper.rb` for first-party coverage reporting.

Current coverage settings:

- Line coverage is enabled.
- Branch coverage is enabled.
- Coverage output directory: `coverage/`
- Minimum required coverage (enforced):
	- line: `80%`
	- branch: `80%`

If either threshold is below 80%, the test run exits non-zero.

### Generate coverage report locally

```bash
bundle exec rails test

or

bin/ci
```

Then open:

- `open coverage/index.html`

### Notes

- Coverage filters exclude `test/`, `config/`, `vendor/`, and `docs/`.
- In parallel test runs, coverage results are merged via SimpleCov configuration in `test/test_helper.rb`.

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

Do not use `RAILS_ENV=production bin/rails db:seed` to create admin access.

- The template's seeded admin account is development-only convenience data.
- Bootstrap production admin users via a controlled manual process (for example a one-off `rails runner` command executed by an operator).

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

