# Metrics Architecture

This application uses an endpoint-first observability model for API metrics. We capture request events in Rails, persist normalized raw metrics, produce endpoint rollups, and then build Blazer dashboards from a mix of raw metrics (current day) and rollups (7/30 day views).

## Design Intent

The current model is optimized for:

- One source of truth for traffic and error trends at endpoint level
- Accurate global latency p95 from raw duration data
- Dashboard performance for 7-day and 30-day windows via rollups

## Data Model

Per API request, the ingestion job writes two raw metrics:

- observability.api.request.count
- observability.api.request.duration_ms

Request status, controller, and action are stored in labels. That allows error metrics to be derived from request count rows instead of writing separate raw error metric names.

## Rollup Model

Endpoint rollups are the main dashboard source:

- observability.api.endpoint.requests
- observability.api.endpoint.client_errors
- observability.api.endpoint.server_errors
- observability.api.endpoint.duration.avg_ms
- observability.api.endpoint.duration.p95_ms

Global request and error charts are derived in SQL by aggregating endpoint rollups.

To preserve statistical correctness, one global latency rollup remains:

- observability.api.duration.p95_ms

This avoids incorrectly averaging endpoint p95 values.

## Searchjoy Rollups

Search analytics are rolled up from `searchjoy_searches` via `Searchjoy::SearchjoyRollupsJob`.

Rollup series:

- searchjoy.searches
- searchjoy.searches.by_query (dimension: query)
- searchjoy.searches.conversion_rate

Behavior:

- The rollup job supports `hour` and `day` windows.
- `searchjoy.searches.by_query` groups by `normalized_query` and stores the group in the `query` dimension.
- `searchjoy.searches.conversion_rate` is computed as the average of `(converted_at IS NOT NULL)::int` for each window.

Rollups are persisted in the shared `rollups` table alongside API rollups.

## Retention Policy

Retention is enforced by `MetricsRetentionJob`.

Current windows:

- Raw API metrics (`metrics` table): 30 days
- Raw Searchjoy records (`searchjoy_searches` and `searchjoy_conversions`): 30 days
- Hourly rollups (`rollups.interval = hour`): 90 days
- Daily rollups (`rollups.interval = day`): 2 years

Because rollup cleanup is interval-based, retention applies to all rollup names, including both API and Searchjoy rollup series.

## Rollup And Retention Interaction

`Metrics::Rollups::MetricsRollupJob` builds rollups from raw tables (`metrics` and Searchjoy tables) for a specific time window, while `MetricsRetentionJob` deletes raw records older than 30 days.

Practical implications:

- Rolling up current-day and recent hourly windows is very safe because source rows are well inside raw-data retention.
- If rollup execution is delayed, you still have a 30-day source-data recovery window for backfilling missed rollups.
- Manual rollup triggers should target windows newer than 30 days when relying on raw-source recomputation.
- Backfills older than 30 days cannot be recomputed from raw tables in this default policy and should rely on existing rollups (if present) or external archives (if you have them).

Scheduling guidance:

- Run rollup jobs frequently (for example hourly for `hour` windows, daily for `day` windows).
- Run retention after rollup jobs on normal schedules to avoid deleting raw rows before expected aggregation has occurred.
- For one-off/manual backfills, execute rollups before running retention when operating close to the 30-day boundary.

## Dashboard Query Strategy

- Current day queries: read raw metrics for highest freshness and hourly detail.
- 7-day and 30-day queries: read rollups for lower query cost and faster dashboards.

## End-To-End Flow

```mermaid
flowchart LR
  A[API Request] --> B[Controller]
  B --> C[ActiveSupport Notification]
  C --> D[Observability Subscriber]
  D --> E[ApiRequestMetricsJob]

  E --> F[Payload Validation]
  F --> G[ApiRequestMetricsBuilder]
  G --> H[(metrics table)]

  H --> I[Metrics::Rollups::ApiEndpointsJob]
  H --> J[Metrics::Rollups::ApiObservabilityJob]

  I --> K[(rollups table endpoint series)]
  J --> L[(rollups table global p95)]

  H --> M[Blazer current day queries]
  K --> N[Blazer 7/30 day queries]
  L --> N
```

## Operational Notes

- Raw metrics are retained for debugging and accurate recomputation.
- Endpoint rollups are treated as the primary aggregate layer for volume and error trends.
- Searchjoy rollups follow the same shared rollup retention lifecycle as API rollups.
- Blazer dashboard SQL is intentionally simple at read time, with complexity pushed into rollup jobs.

## Installing Default Blazer Content

To bootstrap the bundled queries and dashboard entries:

1. `bin/rails blazer:default_queries:install`
2. `bin/rails blazer:install_dashboards`

Notes:

- The default-queries task installs versioned query records with idempotent installation markers.
- The dashboard task wires those queries into the API Observability dashboard.
- Both tasks are safe to rerun.