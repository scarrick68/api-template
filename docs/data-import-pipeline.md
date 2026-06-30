# Data Import Pipeline

This document describes the batch-oriented import architecture using GoodJob.

## Purpose

The import system separates concerns so large imports are observable, resumable, and operationally safe.

- `DataArtifact` stores uploaded file plus schema/version metadata.
- `DataImportRun` tracks one import attempt and its counters/status/errors.
- GoodJob batch jobs orchestrate chunked processing.
- Importer classes own validation, transforms, and persistence strategy.

## Architecture

```text
DataArtifact
	uploaded file + schema/version metadata

DataImportRun
	one attempt to import an artifact
	status/counts/errors/audit trail

StartImportJob
	top-level GoodJob batch job
	reads artifact
	splits rows into orchestration chunks (for example ~500 rows)
	enqueues ProcessBatchJob per chunk

ProcessBatchJob
	receives one chunk
	calls importer.process_rows(run:, rows:)
	updates DataImportRun counters/errors

FinalizeImportJob
	GoodJob batch callback
	runs importer.finalize(run:)
	marks run succeeded/failed
```

Important boundary:

- Jobs orchestrate execution and state transitions.
- Importers decide how rows are validated and persisted.
- Jobs do not encode persistence details.

## GoodJob Batch Flow

```mermaid
flowchart TD
	A["(USER) Start import for DataArtifact"] --> B["(SYSTEM) Create DataImportRun status=pending"]
	B --> C["(SYSTEM) Enqueue StartImportJob"]
	C --> D["(SYSTEM) StartImportJob creates GoodJob::Batch"]
	D --> E["(SYSTEM) Read rows from artifact and split into orchestration chunks"]
	E --> F["(SYSTEM) Enqueue ProcessBatchJob per chunk in batch"]
	F --> G["(SYSTEM) ProcessBatchJob calls importer.process_rows(run:, rows:)"]
	G --> H["(SYSTEM) with_lock update run counters and error_details"]
	H --> I["(SYSTEM) Batch callback -> FinalizeImportJob"]
	I --> J["(SYSTEM) importer.finalize(run:) optional"]
	J --> K["(SYSTEM) Mark run succeeded or failed with finished_at"]
```

## Importer Contract

Importer classes should inherit from `DataImports::BaseImporter` and return structured totals for each invocation.

```ruby
class DataImports::BaseImporter
	Result = Data.define(
		:records_seen,
		:records_imported,
		:records_failed,
		:error_details
	)

	# Orchestration default. Importers may process sub-batches internally.
	def self.batch_size = 500

	def self.process_rows(run:, rows:)
		raise NotImplementedError
	end

	def self.finalize(run:)
		# optional
	end
end
```

Expected `process_rows` behavior:

- Validate and transform incoming rows.
- Persist according to importer strategy.
- Return `Result` with counts and structured row-level errors.

## Importer Strategy Recommendations

Default recommendation for most importers:

- Use `upsert_all` for validated rows per job chunk or importer sub-batch.
- Use `activerecord-import` when you specifically need its features
- Single-row persistence is not advised, but possible if you should find a reason to do so.

## Chunk Size Guidance

The rows sent to `ProcessBatchJob` are orchestration chunks, not a strict importer processing unit.

This means an importer can:

- process all received rows directly,
- split received rows into smaller internal slices,
- or stage and aggregate rows before persisting.

Why this matters:

- orchestration chunking keeps large files interruptible and non-blocking,
- importer-internal batching can tune memory and database write patterns,
- queue-level chunk size and persistence-level batch size can evolve independently.

## Counter Update Pattern

`ProcessBatchJob` should merge importer results into `DataImportRun` under a lock to avoid lost updates.

```ruby
run.with_lock do
	run.update!(
		records_seen: run.records_seen + result.records_seen,
		records_imported: run.records_imported + result.records_imported,
		records_failed: run.records_failed + result.records_failed,
		error_details: run.error_details + result.error_details
	)
end
```

## Operational Notes

- Keep importer operations idempotent where possible (natural keys + upsert patterns).
- Cap or summarize row errors for very large failures to avoid unbounded payload growth.
- Raise terminal errors for non-recoverable conditions so run status is accurate.
- Use `finalize` for post-import consistency checks or rollup steps, not core row ingestion.

