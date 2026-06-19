# ADR 0004: Single-Database Solid Stack

## Status

Accepted

## Date

2026-06-19

## Context

Rails 8 Solid components (Solid Queue, Solid Cache, Solid Cable) can run on dedicated databases or the primary application database.

For template simplicity and default operability, multi-database complexity can be an adoption barrier.

## Decision

Default to a single PostgreSQL database in production for:

- primary app data
- Solid Queue
- Solid Cache
- Solid Cable
- Flipper feature flag storage
- Metrics collection and rollups
- Analytics via Ahoy and Searchjoy
- Error tracking via Solid Errors
- Operational tools like PgHero and Blazer
- Field Test A/B testing data

Deploy with separate process types (`web` and `job`), while sharing the same database connection target.

## Rationale

- Reduces infrastructure complexity in initial deployments.
- Improves out-of-the-box operability for template consumers.
- Improves compatibility with a wider range of hosting providers. Many do not allow multiple databases per instance (no CREATE DATABASE command allowed).
- Avoids early multi-DB migration/ops burden.

## Consequences

Positive:

- Faster setup and fewer moving parts.
- Simpler environment variable and connection management.
- Good baseline for small-to-medium workloads.

Tradeoffs:

- Background job/cache/cable workload shares DB resources with OLTP traffic.
- Larger deployments may eventually need workload isolation and dedicated data stores.
- Tradeoffs of job processing latency and DB chatter

## Extensions

- Read replicas for jobs and analytics
- Small dedicated DB (or Redis) for jobs and caching. SolidQueue is supposed to be on a sepaarate datastore by default, but we have merged it into the main DB for aforementioned reasons.

## Related Docs

- ../../README.md
