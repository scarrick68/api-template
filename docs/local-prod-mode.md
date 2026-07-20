# Local Production Mode Boundaries

This document defines what `bin/prod-local` is expected to support and what is intentionally out of scope.

## Purpose

`bin/prod-local` is a pragmatic smoke-test mode for running the API with production environment settings on a local machine.

It is not intended to replicate full cloud production infrastructure.

## Configuration Model

Local production mode uses two files:

- Generated defaults: `.env.production.local`
- User overrides: `.env.production.local.user`

Load order when running `bin/prod-local`:

1. Load `.env.production.local`
2. Load `.env.production.local.user` and override any duplicate keys

This keeps generated defaults rerunnable while preserving user-owned overrides. This enables extension of the local prod mode as your app grows.

### Safe rerun behavior

- `local_prod:setup_env` creates `.env.production.local` when missing.
- `local_prod:setup_env` backfills missing required defaults in `.env.production.local`.
- `local_prod:setup_env` creates `.env.production.local.user` when missing.
- User edits in `.env.production.local.user` are never overwritten by setup.

## Expected To Work

- Boot Rails in `RAILS_ENV=production` on local host/port.
- Infer a local `DATABASE_URL` from development database config when not explicitly provided.
- Reuse development database for local prod mode.
- FE / BE features that are not dependent on external services such as email, payments, etc... YMMV. This will depend on your app's specific features and dev functionality provided by your gem dependencies.

## Expected Not To Work (Out Of Scope)

- Full production parity for infra services (managed networking, secrets managers, cloud IAM).
- Production-grade secret management from local plain env files.
- Automated provisioning of missing databases or infra dependencies.
- Guaranteeing feature parity with every production deployment customization.

## Failure Conditions (By Design)

`local_prod:setup_env` should fail fast when:

- PostgreSQL catalog cannot be queried.
- No non-template databases are returned.
- Selected local development database does not exist.

These are setup errors and should be fixed explicitly rather than silently bypassed.

## CI Coverage

- CI includes a non-blocking `prod-local-smoke` job that boots `bin/prod-local` and checks `GET /up`.
- The job is informational (`continue-on-error: true`) so it surfaces regressions without blocking merges.
