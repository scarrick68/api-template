# ADR 0002: Dual Authentication Boundary For API And Admin

## Status

Accepted

## Date

2026-06-19

## Context

The template supports both API clients and browser-based workflows (currently administrative interfaces). These consumers have fundamentally different authentication needs, trust boundaries, session lifecycles, and routing requirements.

While it is possible to unify these surfaces behind a single authentication mechanism, doing so introduces additional coupling between systems that are otherwise independent. It can also blur security boundaries and increase the complexity of integrating operational and administrative tooling.

Many Rails ecosystem tools assume traditional session-based authentication and route constraints. Some provide extension points for custom authentication strategies, while others offer only basic configuration options and are not designed for deep customization. By using token-based authentication for API consumers and standard Devise sessions for browser-based workflows, the template can integrate cleanly with these tools while keeping authentication concerns straightforward and well-defined.

This approach leverages established Rails conventions, reduces implementation complexity, and provides a clear separation between external API access and internal administrative capabilities.


## Decision

Use separate authentication domains:

- API surface (`/api/v1/*`) uses token authentication via devise_token_auth.
- Internal/browser routes use Devise session authentication for admin operators.

Identity roles remain distinct:

- `User` is API/app identity.
- `Admin` is operator identity.

## Rationale

- Prevents token-authenticated API clients from implicitly accessing admin browser tools.
- Preserves clear route and controller responsibilities.
- Keeps API and browser auth behavior independently testable.

## Consequences

Positive:

- Explicit security boundaries between API and admin flows.
- Reduced accidental privilege crossover.
- Cleaner integration tests by auth domain.

Tradeoffs:

- More auth-related configuration and test coverage.
- Teams must consistently choose the correct helper family (`current_user` vs `current_admin`). However, the boundary is very clear at this point: current_user under /api/v1/*, and current_admin everywhere else. This should make it pretty intuitive.
