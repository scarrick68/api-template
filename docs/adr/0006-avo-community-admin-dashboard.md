# ADR 0006: Avo Community Admin Dashboard

## Status

Accepted

## Date

2026-06-24

## Context

The template needs a well-featured, mobile-friendly, internal admin dashboard for operator workflows. This will allow a high degree of default operator functionality even when away from a desktop, which is a practical advantage for small teams managing the app from anywhere.

## Decision

Adopt Avo Community as the default admin dashboard surface.

- Mount Avo at `/avo`.
- Use `AVO_LICENSE=community` by default.
- Keep optional support for `AVO_LICENSE_KEY` when a paid Avo tier is explicitly adopted.
- Require admin session authentication for Avo in non-development route configuration.
- Keep Avo internal authentication configured with `current_admin` and `authenticate_admin!`.

## Rationale

- Provides a modern admin dashboard with low template maintenance overhead.
- Other options are either less feature rich, DSL heavy, require FE artifacts that are otherwise not needed in the project (Sass for activeadmin), and are usually not mobile-friendly.
- Aligns with Rails-native Hotwire/Turbo patterns for fast, low-friction operator interactions.
- Supports mobile-friendly administration, which is a practical advantage for small teams managing the app from anywhere.
- Keeps the default licensing posture open and cost-conscious.
- Preserves existing admin security posture by aligning with Devise admin session authentication.
- Uses defense-in-depth for a sensitive operator surface.

## Consequences

Positive:

- Clear default admin dashboard choice and operational path.
- Reduced dashboard scaffold/maintenance burden in the template.
- Security posture remains consistent with internal tools policy.

Tradeoffs:

- Adds another mounted operator interface that must remain covered by auth tests.
- Teams that do not want Avo must remove route/config/test surface explicitly.

## Related Docs

- ../../README.md
- ../template-features.md
- ./0003-admin-session-protection-for-internal-tools.md
