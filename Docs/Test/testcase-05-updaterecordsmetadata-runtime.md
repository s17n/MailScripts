# Testcase 05: updateRecordsMetadata (Developer Notes)

## Scope

Validates `DocLibrary.updateRecordsMetadata(...)` for configured fixture records from JSON.

What this testcase must guarantee:

- deterministic fixture resolution (`databaseName` + exact `recordFilename`),
- `pilot-name-comments` scenario behavior,
- overwrite behavior for sentinel name/comment,
- restoration of full mutable record state after run.

## Diagrams

- Overview: `Docs/testcases-sequence-overview.md`
- Testcase 05 (reduced): `Docs/testcase-05-sequence-diagram.md`

## Execution

Primary entrypoint:

```bash
./scripts/run-testcase-05.sh
```

Compile + run (recommended during development):

```bash
./scripts/run-testcase-05.sh --compile
```

Runner architecture:

- wrapper: `scripts/run-testcase-05.sh`
- shared runner: `scripts/run-testcase.sh`
- source: `src/tests/updateRecordsMetadata/testcase-05-updaterecordsmetadata.applescript`
- compiled: `tests/updateRecordsMetadata/testcase-05-updaterecordsmetadata.scpt`

Exit codes:

- `0`: PASS
- `1`: testcase assertion failure
- `2`: execution/infrastructure failure

## Test Data Contract

JSON source:

- `Configuration/tests/testcase-05-updaterecordsmetadata-cases.json`

Schema:

```json
[
  {
    "databaseName": "<exact database name>",
    "recordFilename": "<exact filename.ext>",
    "scenarioId": "pilot-name-comments"
  }
]
```

Validation rules enforced by `TestLib`:

- top-level must be a non-empty array,
- each field must exist and be a non-empty string,
- fixture lookup is name-derived from `recordFilename` and then filename-verified.

## Current Design Decisions

- Shared harness is in `TestLib`:
  - `findRecordByFilenameInDatabase(...)`
  - `runWithCleanup(...)`
  - `runCasesWithSummary(...)`
  - `loadTestCases(...)` (via `loadTestCase05Cases(...)`)
- `runTestCase(...)` captures and restores:
  - tags,
  - name,
  - comments,
  - relevant custom metadata fields (`pCustomMetadataFields ∪ pCommentsFields`).
- Scenario preconditions are strict:
  - `pNameTemplate` configured,
  - `pCommentsFields` non-empty,
  - date dimensions present in tags.

## Extension Guide

To add a new fixture:

1. Append a case to `Configuration/tests/testcase-05-updaterecordsmetadata-cases.json`.
2. Keep `databaseName` and `recordFilename` exact.

To add a new scenario:

1. Add a new `scenarioId` in JSON.
2. Implement branch in `runScenarioById(...)`.
3. Ensure full state restoration remains valid for new mutations.

## Practical Failure Patterns

Actionable failures during development:

- `No database found with exact name: ...`
- `No record found ...` / `Multiple records found ...`
- `Found record by name ..., but filename differs ...`
- `JSON file not found` / parse/schema failures
- precondition failures for template/comments/date dimensions
- cleanup failures restoring metadata/state

Known environment-level noise/failures (not business-logic regressions):

- `FAIL at step 'resolve config path' (-1708): ... «event earsffdr»`
- `Connection Invalid error for service com.apple.hiservices-xpcservice`
