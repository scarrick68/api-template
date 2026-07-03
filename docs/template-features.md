# Template Features Quick Reference

A production-ready Rails 8.1 API template focused on developer velocity, operational simplicity, and long-term maintainability.

## Developer Experience

* Rails 8.1 API-first application skeleton with opinionated conventions and sensible defaults.
* Fast local CI pipeline via `bin/ci` with integrated quality and security checks.
* RubyCritic code quality metrics integrated via `bin/quality` and included in CI quality checks.
* App renaming utility via `bin/template_rename` for first-pass project bootstrap naming. Make the project your own with a single command.
* Full application test suite executes in parallel, enabling complete CI runs in approximately 15 seconds.
* SimpleCov coverage reporting with enforced thresholds and 98% coverage on template code.
* Service object architecture under `app/services/svc` for clear business logic boundaries.
* Contract-based request validation under `app/contracts`.
* Blueprinter-based API serialization conventions.
* Lightning-fast, low-memory pagination powered by Pagy.
* Strong Migrations enabled by default to guide safe schema changes with low friction in early development and increasing safety value as projects grow.

## API Platform

* Versioned JSON API namespace under `/api/v1`.
* Token authentication for API clients via devise_token_auth.
* Separate browser and admin authentication via Devise sessions.
* Explicit testing of authentication boundaries between API and administrative surfaces.
* Standardized JSON error envelopes and exception mapping.
* Policy-based authorization with an explicit deny-by-default security posture.
* OpenAPI source document maintained at `docs/openapi.yml`.
* ReDoc-powered API documentation with admin-only access outside development environments.
* Performant, batch-oriented, durable, high-visibility, versioned, dry-run capable, observable, state machine driven, multi-cloud blob store compatible data import pipeline with `DataArtifact` + `DataImportRun`, schema-aware importer registry, GoodJob orchestration, and AASM-driven run/artifact state transitions (see `docs/data-import-pipeline.md`).

## Observability & Operations

* Built-in first-party metrics pipeline with endpoint-level visibility, automatic rollups, and default retention policies.
* Blazer-powered API observability dashboards built-in, and backed by raw metrics for real-time visibility and rollups for longer-term trend analysis.
* Searchjoy rollups for daily/hourly search volume, query breakdowns, and conversion rate, stored in the shared `rollups` table.
* Unified data retention policy: raw metrics/search records are short-lived, rollups are retained longer for historical trend analysis.
* Searchkick + Elasticsearch integration with health checks included. (Elasticsearch service is included in development env, but not included for any other env. Determine a 3rd party provider or self-hosting strategy based on your needs.)
* PgHero for database monitoring and performance analysis.
* GoodJob dashboard for background job observability and operational control.
* Searchjoy search analytics integration.
* Structured JSON request logs in production via Lograge, plus a lightweight `AppEvent` wrapper for application-level events.
* Lograge is intentionally used as an 80/20 structured-logging baseline right now; full logger-stack replacement was deferred as too heavy for this stage.
  - Request actor enrichment is isolated by auth surface (User / Admin)
* "We have Datadog and New Relic at home" philosophy: meaningful observability without mandatory SaaS dependencies.
* Rack::Attack throttling for authentication endpoints and write-heavy API surfaces.

## Product Experimentation & Growth

* First-party feature flags powered by Flipper with ActiveRecord-backed storage and administrative UI.
* Field Test A/B testing framework integrated with Ahoy user identification.
* Ahoy server-side analytics scaffolding for product usage tracking and experimentation.

## Single-Database Architecture

Designed around a practical single-database deployment model to reduce infrastructure complexity, operational overhead, and hosting costs while still providing many capabilities often delegated to external services.

Built-in support includes:

* Background jobs via GoodJob
* Caching via Solid Cache
* Feature flags via Flipper
* Error reporting via Solid Errors
* Metrics collection and rollups
* Metrics dashboards via Blazer
* Database monitoring via PgHero
* Background job observability via GoodJob dashboard
* A/B testing via Field Test
* Analytics via Ahoy
* Search analytics via Searchjoy
* Search analytics rollups and retention via Searchjoy + Rollup

The metrics system is designed to be forward-compatible with Prometheus and OpenTelemetry should your infrastructure requirements grow over time.

## Operator Tooling

The following operational tools are preconfigured and mounted with administrative protections outside development environments:

* Admin tools index dashboard (`/admin/tools`) that provides a single entrypoint for operator tooling and links to available mounted tools.

* PgHero
* GoodJob
* Blazer
* Flipper
* Searchjoy
* Solid Errors
* ReDoc API documentation
* Field Test admin UI
* RubyCritic code quality report (`tmp/rubycritic/overview.html`)

and other operator-focused tooling as the template evolves.

### Admin Tools Index Dashboard

The admin tools index dashboard is an operator-focused landing page that centralizes links for internal tools.

* Route: `/admin/tools`
* Access: session-authenticated `Admin` users (outside development environments)
* Purpose: provide one stable navigation surface for internal dashboards and operational tooling
* Current linked tools are discovered from mounted routes and rendered with friendly names in the dashboard UI

## Deployment Philosophy

* Easy to deploy.
* Economical to operate.
* Minimal infrastructure requirements.
* Strong defaults for security, observability, testing, and maintainability.
* Built to scale from side projects to production applications without requiring a platform rewrite.
