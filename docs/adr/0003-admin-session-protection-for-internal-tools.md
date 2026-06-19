# ADR 0003: Admin Session Protection For Internal Tools

## Status

Accepted

## Date

2026-06-19

## Context

The template mounts several operational tools (for example PgHero, Blazer, Mission Control Jobs, Flipper, Field Test, Solid Errors, and docs UI). These tools are useful for operators but should not be publicly available in non-development environments.

## Decision

Use environment-aware route protection:

- Development: mounted tools are directly accessible for local debugging.
- Non-development: mounted tools are available only through authenticated admin session routes.

Token-authenticated API requests are not treated as valid admin access for these browser-oriented endpoints.

## Rationale

- Keeps local developer ergonomics high.
- Protects operational interfaces in test/production.
- Aligns tooling access with operator workflows and session controls.

## Consequences

Positive:

- Consistent access policy across mounted tools.
- Lower accidental exposure risk for sensitive operator interfaces.
- Clear testing strategy for session-only routes.
- Easier admin restrictions with built-in Devise functionality.

Tradeoffs:

- Environment-specific route behavior must be documented and tested.
- Operator onboarding requires session-auth setup in non-development.

## Related Docs

- ../../README.md
