# Strong Migrations

This template includes Strong Migrations by default to improve schema-change safety without making normal development painful.

## Why this is enabled by default

- It catches risky migration patterns early and provides safer alternatives.
- It works well with modern AI-augmented development workflows because it gives clear, actionable feedback when a generated migration is unsafe. AI / agents can just fix the given issue and regenerate the migration automatically.
- It keeps early project iteration low-friction while adding more value as tables, traffic, and migration risk grow.

## Current default posture

Current configuration lives in config/initializers/strong_migrations.rb.

Enabled defaults in this template:

- Existing historical migrations are marked safe with start_after.
- lock_timeout is set to 10 seconds.
- statement_timeout is set to 1 hour for migration execution.
- auto_analyze is enabled after index creation.

Not enabled by default right now:

- safe_by_default
- target_version
- custom checks
- remove_invalid_indexes

This keeps the baseline conservative and compatible while still providing meaningful safety checks.

## Recommended workflow

1. Generate migrations normally.
2. Run migrations locally as usual.
3. If Strong Migrations flags an issue, follow the safer pattern it recommends.
4. If you must bypass a check, use explicit review and document the reason in the migration.

In AI-assisted workflows, treat Strong Migrations output as a review gate for migration correctness and operational safety.

## Growth path

As a project matures, Strong Migrations shifts from a helpful warning layer to a high-value operational guardrail by reducing the chance of risky schema changes reaching production.

Teams can incrementally tighten posture over time (for example safe_by_default and custom checks) once schema complexity and deployment risk increase.
