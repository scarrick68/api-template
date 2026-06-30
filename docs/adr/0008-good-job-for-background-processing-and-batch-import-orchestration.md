# ADR 0008: GoodJob For Background Processing And Batch Import Orchestration

## Status

Accepted

## Date

2026-06-30

## Context

The project is moving from Solid Queue to GoodJob for background processing.

We need a backend that:

- is PostgreSQL-backed and operationally durable,
- integrates cleanly with Active Job,
- supports recurring scheduling,
- and provides robust orchestration primitives for large data imports.

The data import pipeline specifically benefits from first-class batch semantics:

- enqueue a coordinated set of chunk jobs,
- track completion at the batch level,
- and run finalize logic via batch callbacks.

## Decision

Adopt GoodJob as the background job backend.

- Use GoodJob as the Active Job adapter.
- Use GoodJob recurring scheduling for cron-like jobs.
- Use GoodJob batch jobs and batch callbacks for import-run orchestration.

Solid Queue-specific infrastructure is no longer the primary queue backend.

## Rationale

- PostgreSQL-backed persistence fits the current operational model.
- GoodJob provides a broader out-of-the-box feature set needed by this project.
- Batch and callback support maps directly to the import workflow:
  - start import,
  - process chunk jobs,
  - finalize when the batch completes.
- Reduces custom coordination code for multi-step imports.

## Consequences

Positive:

- Better alignment between job backend capabilities and import pipeline needs.
- Cleaner implementation for chunked, interruptible imports.
- Stronger operational visibility through GoodJob dashboard and batch state.

Tradeoffs:

- Migration effort from prior queue-specific assumptions/tests/config.
- Team must standardize on GoodJob idioms for scheduling and orchestration.

## Related Docs

- ../../data-import-pipeline.md
- ../../template-features.md
- ../README.md
