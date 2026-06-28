# ADR 0007: Lograge As The 80/20 Structured Logging Baseline

## Status

Accepted

## Date

2026-06-28

## Context

The template needed a practical structured logging baseline early in development:

- Produce machine-readable request logs quickly.
- Keep implementation and maintenance overhead low.
- Avoid broad changes to Rails logging internals before operational needs are clearer.

At this stage, request-level JSON output and a consistent schema provide most of the value needed for local debugging and downstream log aggregation.

More comprehensive logging-stack replacements were considered (for example, replacing the default Rails logger stack with a semantic logging framework), but those options require a larger architectural commitment and broader migration risk than is appropriate right now.

## Decision

Use Lograge as an 80/20 solution for structured request logging.

- Keep the Rails logging stack largely intact.
- Use Lograge with a custom structured payload builder for request logs.
- Continue using lightweight application-level structured events via `AppEvent`.

Do not adopt a full logging-stack replacement at this time.

## Rationale

- Fast path to useful structured logs with limited code and configuration.
- Lower integration risk while core product and operational requirements are still evolving.
- Preserves flexibility to revisit the logging architecture later with real production feedback.

## Consequences

Positive:

- Immediate structured request logging with minimal disruption.
- Smaller decision surface and easier onboarding for contributors.
- Clear separation between request logs (Lograge) and explicit app events (`AppEvent`).

Tradeoffs:

- Not as feature-rich as dedicated semantic logging platforms.
- Some advanced capabilities remain future work if needed.

## Future Direction

If Rails introduces a first-party structured logging solution suitable for this template, prefer adopting that upstream Rails approach over third-party full-stack logger replacement, subject to migration cost and ecosystem maturity.
