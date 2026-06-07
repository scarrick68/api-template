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

## API Versioning

API endpoints should be added under `/api/v1`.

The `/api/` namespace defaults to JSON responses.

- Canonical hello endpoint: `GET /api/v1/hello`

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

