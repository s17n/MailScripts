# Testcase 04: classifyRecords (Developer Notes)

## Scope

Validates `DocLibrary.classifyRecords(...)` for configured fixture records from JSON.

What this testcase must guarantee:

- deterministic fixture resolution (`databaseName` + exact `recordFilename`),
- `pilot-date-tags` scenario behavior,
- trace metrics for `classifyRecords` (`callCount = 1`, durations > 0),
- record tag cleanup on success and failure.

## Diagrams

- Overview: `Docs/testcases-sequence-overview.md`
- Testcase 04 (reduced): `Docs/testcase-04-sequence-diagram.md`
- classifyRecords detail: `Docs/testcase-04-classifyrecords-detail-sequence.md`

## Execution

Primary entrypoint:

```bash
./scripts/run-testcase-04.sh
```

Compile + run (recommended during development):

```bash
./scripts/run-testcase-04.sh --compile
```

Runner architecture:

- wrapper: `scripts/run-testcase-04.sh`
- shared runner: `scripts/run-testcase.sh`
- source: `src/tests/classifyRecords/testcase-04-classifyrecords.applescript`
- compiled: `tests/classifyRecords/testcase-04-classifyrecords.scpt`

Exit codes:

- `0`: PASS
- `1`: testcase assertion failure
- `2`: execution/infrastructure failure

## Test Data Contract

JSON source:

- `Configuration/tests/testcase-04-classifyrecords-cases.json`

Schema:

```json
[
  {
    "databaseName": "<exact database name>",
    "recordFilename": "<exact filename.ext>",
    "scenarioId": "pilot-date-tags"
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
  - `loadTestCases(...)` (via `loadTestCase04Cases(...)`)
- Fixture precondition handling is best-effort:
  - testcase tries to remove existing Year/Month/Day tags,
  - strict "missing before run" assertions are only applied when cleanup-to-missing succeeded,
  - core assertion remains: Year/Month/Day must be set after `classifyRecords(...)`.
- Runtime metadata lookup in base library is best-effort and should not block classification flow.

## Extension Guide

To add a new fixture:

1. Append a case to `Configuration/tests/testcase-04-classifyrecords-cases.json`.
2. Keep `databaseName` and `recordFilename` exact.

To add a new scenario:

1. Add a new `scenarioId` in JSON.
2. Implement branch in `runScenarioById(...)`.
3. Keep scenario deterministic (explicit preconditions, explicit postconditions, cleanup-safe).

## Practical Failure Patterns

Actionable failures during development:

- `No database found with exact name: ...`
- `No record found ...` / `Multiple records found ...`
- `Found record by name ..., but filename differs ...`
- `JSON file not found` / parse/schema failures
- cleanup failures while restoring tags

Non-authoritative noise you may still see:

- transient `osascript ... error -1763` lines; rely on final PASS/FAIL summary + exit code.
