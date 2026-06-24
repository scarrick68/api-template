# ADR 0006: Template Rename Utility Is Best-Effort

## Status

Accepted

## Date

2026-06-24

## Key Takeaway

- `bin/template_rename` is a convenience bootstrap tool intended for mostly one-time use. It is best-effort and does not guarantee perfect repeated back-and-forth renames.

## Context

The API template includes a rename utility to quickly move from `api-template` naming to project naming.

The utility covers high-value paths and naming tokens, and includes warning scans for leftovers. It is not a full parser/AST semantic rewrite across all file types, generated outputs, and historical artifacts.

Implementation context: the utility was vibe coded as a pragmatic bootstrap helper, then reviewed with targeted unit tests and smoke validation.

Observed behavior:

- First rename flow is effective for project bootstrap.
- Subsequent rename support exists but can have edge cases, especially around `Api` suffix/token variants.
- Local generated artifacts (for example logs/coverage) may still reference previous names.

## Decision

Keep the current approach and position it as:

1. A practical convenience utility.
2. Primarily a one-time bootstrap operation.
3. Best-effort for subsequent renames, with explicit warnings and manual follow-up.

Document reset guidance for users who need a pristine post-rename local environment.

## Rationale

- Maximizes developer speed at project creation time.
- Avoids introducing a complex and brittle full-codemod system.
- Keeps maintenance cost and risk proportionate to the use case.
- Provides reasonable safety through warnings and tests.

## Validation Evidence

The utility was validated by:

1. Unit tests for `TemplateRenameCommand`.
2. Running the rename tool directly.
3. Running `bin/ci` successfully after rename.
4. Starting Rails server successfully (`rails s`).

## Consequences

Positive:

- Fast project bootstrap rename path.
- Clear user messaging about guarantees and manual follow-up.
- Practical reliability for the primary use case.

Tradeoffs:

- Repeated rename loops are not guaranteed to be exhaustive.
- Some generated/local artifacts may keep old-name references until explicitly cleaned.

## Operational Guidance

For users requiring a pristine local state after rename, clear generated artifacts and optionally reset local workspace state as documented in `docs/template-rename.md`.

## Related Docs

- ../template-rename.md
- ../README.md
