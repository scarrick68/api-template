# Documentation

This directory contains product and operational documentation for the API template.

## Contents

- OpenAPI specification: openapi.yml
- Authentication model and safety defaults: authentication.md
- Database migration safety defaults: strong-migrations.md
- Metrics model and observability pipeline: metrics-model.md
- Data import pipeline and execution flow: data-import-pipeline.md
- Structured logging (Lograge + AppEvent): logging.md
- Template features quick reference: template-features.md
- Rake task command pattern: rake-task-command-pattern.md
- Admin tools index dashboard feature: template-features.md#admin-tools-index-dashboard
- Ruby code quality metrics (RubyCritic): rubycritic.md
- Template rename utility guide: template-rename.md
- Architecture decisions: adr/
- Deployment and launch runbooks: deploy/

## Architecture Decision Records

- Endpoint-first API metrics modeling: adr/0001-endpoint-first-api-metrics-modeling.md
- Dual auth boundary for API and admin: adr/0002-dual-auth-boundary-for-api-and-admin.md
- Admin session protection for internal tools: adr/0003-admin-session-protection-for-internal-tools.md
- Single-database Solid stack: adr/0004-single-database-solid-stack.md
- Separate browser and API base controllers: adr/0005-separate-browser-and-api-base-controllers.md
- Template rename utility is best-effort: adr/0006-template-rename-utility-is-best-effort.md

## Deployment And Launch Guides

- Production email setup: deploy/production-email-setup.md
- Production CORS setup: deploy/production-cors-setup.md
