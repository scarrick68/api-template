# Template Rename Utility

## Purpose

`bin/template_rename` is a convenience utility to rename the API template from `api-template` to a project-specific app name.

This utility is designed to be used once, near project bootstrap. It is intentionally pragmatic, not airtight. It is not a full codemod or AST-based semantic rewrite, and it does not guarantee perfect repeated back-and-forth renames.

It has been tried with back and forth renames and that mostly works apart from one or two extra "Api" prefixes or suffixes in the README. However, we are ignoring that bc constantly renaming back and forth is not a common use case. The utility is intended to be used once, at project bootstrap.

Implementation note: this utility was vibe coded for speed, then unit tests reviewed and practical smoke validation.

## Current Behavior Summary

- Supports first rename from the template default.
- Supports subsequent rename attempts with warning and interactive confirmation.
- Rewrites selected known files and known naming tokens.
- Scans for remaining references and prints warning paths for manual follow-up.

## Known Limitations

The utility mostly, but not perfectly, supports repeated back-and-forth renames.

Known rough edge:

- `Api` suffix and similar token variants can drift in some paths, so repeated renames are not guaranteed to be clean.

The command intentionally does not guarantee a pristine all-history/all-artifact rename state.

## Validation Performed

In addition to unit tests for `TemplateRenameCommand`, the utility was validated by running:

1. `bin/template_rename ...`
2. `bin/ci`
3. `rails s`

All three completed successfully in validation runs.

## Non-Pristine Artifacts After Rename

After rename, some generated/local artifacts may still contain old names. This is expected and not considered a product correctness issue by default.

Typical examples:

- `log/*`
- `tmp/*`
- `coverage/*`

The rename command ignores several noisy artifact paths and self-referential implementation/test paths when reporting remaining references, but local generated artifacts can still retain older strings.

## Getting To A Fully Clean Local Environment

If you want a pristine local state after rename, use this sequence from repo root.

1. Stop local processes (`bin/dev`, server, workers).
2. Remove generated artifacts:

```bash
rm -rf log/* tmp/* coverage/*
```

3. Optionally clear local storage artifacts if used:

```bash
rm -rf storage/*
```

4. Rebuild test/runtime artifacts:

```bash
bin/ci
```

5. If you want to discard all uncommitted local changes and return to last commit:

```bash
git restore .
git clean -fd
```

Use step 5 only if you explicitly want to throw away local edits, including all the renaming changes.

## Recommendation

Treat `bin/template_rename` as a one-time bootstrap helper. If substantial manual refactors happen after initial rename, prefer targeted manual edits over repeated automated renames.
