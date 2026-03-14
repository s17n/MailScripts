# Testcase 04: classifyRecords Runtime Check

## Purpose

This test validates `classifyRecords` for a single, explicitly identified fixture record and verifies that trace runtime metrics are produced for the operation.

It covers:

- deterministic record lookup by exact database name and exact filename (including extension),
- functional behavior for the pilot scenario (`pilot-date-tags`),
- runtime metric assertions from the logger trace mechanism.

See also:

- Sequence diagram: `Docs/testcase-04-sequence-diagram.md`

## Refactoring Assessment

Refactoring is currently useful and has been applied for maintainability and diagnostics:

- Scenario dispatch is separated into `runScenarioById(...)` to keep `runTestCase(...)` compact.
- Trace assertions are centralized in `TestLib` via `validateClassifyRecordsTraceMetrics(...)`.
- JSON loading and schema validation are centralized in `TestLib` via a generic `loadTestCases(...)` helper (called by `loadTestCase04Cases(...)`).
- Record lookup and filename validation are centralized in `TestLib` via `findRecordByFilenameInDatabase(...)`.
- Cleanup flow is centralized in `TestLib` via `runWithCleanup(...)`.
- Result aggregation is centralized in `TestLib` via `runCasesWithSummary(...)`.
- Test execution wrappers are unified through `scripts/run-testcase.sh`.

Not refactored intentionally:

- The DEVONthink lookup path remains name-based (derived from filename) plus strict filename validation, because direct filename-query patterns are unstable in DEVONthink 4.2 for this use case.

## Files

- Source: `src/tests/classifyRecords/testcase-04-classifyrecords.applescript`
- Compiled script: `tests/classifyRecords/testcase-04-classifyrecords.scpt`
- Shared runner: `scripts/run-testcase.sh`
- Wrapper runner: `scripts/run-testcase-04.sh`
- Test utility library (source): `src/Libs/TestLib.applescript`
- Test utility library (compiled): `Libs/TestLib.scpt`
- Test case config: `Configuration/tests/testcase-04-classifyrecords-cases.json`
- Production handler under test: `src/Libs/DocLibrary.applescript` (`classifyRecords`)

## Test Data Contract

Test cases are loaded by `TestLib` from:

- `Configuration/tests/testcase-04-classifyrecords-cases.json`

JSON schema (top-level array):

```json
[
  {
    "databaseName": "<exact database name>",
    "recordFilename": "<exact filename.ext>",
    "scenarioId": "pilot-date-tags"
  }
]
```

Rules:

- `databaseName` must exactly match a DEVONthink database name.
- `recordFilename` must include an extension (for example `.pdf`).
- lookup name is derived from `recordFilename` by removing the last extension segment.
- record resolution is done by exact record name match in the selected database.
- after resolution, the record filename (`DTfe`) is validated against the exact `recordFilename` input.
- if zero or multiple records match, the test case fails.
- top-level JSON value must be a non-empty array.
- each field must be a non-empty string.

## Scenario: `pilot-date-tags`

For the resolved record, the test performs:

1. Initialize database configuration (`initializeDatabaseConfiguration`).
2. Validate date configuration:
   - `pClassificationDate` is configured.
   - `pDateDimensions` contains exactly 3 dimensions (Year/Month/Day).
3. Precondition:
   - Year/Month/Day fields are all missing before classification.
4. Execute:
   - `classifyRecords({theRecord})`
5. Postcondition:
   - Year/Month/Day fields are set.
6. Runtime trace checks:
   - metric entry for operation `classifyRecords` exists,
   - `callCount = 1`,
   - `exclusiveTotalMs > 0`,
   - `inclusiveTotalMs > 0`.
7. Post-processing cleanup:
   - restore the original tag list captured before scenario execution,
   - cleanup is executed for both success and failure paths.
8. Error diagnostics:
   - the reported failure step is the original execution step (not overwritten by cleanup step transitions).

## Execution

Recommended (wrapper runner):

```bash
./scripts/run-testcase-04.sh
```

Compile + run from source in one command:

```bash
./scripts/run-testcase-04.sh --compile
```

The wrapper delegates to `scripts/run-testcase.sh`, which supports:

- running an already compiled `.scpt`,
- optional compile-before-run via `--compile` (requires the configured `--source` path).

Exit codes:

- `0`: test passed
- `1`: test failed
- `2`: execution/infrastructure error (for example `osascript` runtime issues)

Manual run (compiled script only):

```bash
osascript "tests/classifyRecords/testcase-04-classifyrecords.scpt"
```

Result format:

- success: `PASS: TOTAL: <n>, PASSED: <n>, FAILED: 0`
- failure: `FAIL: TOTAL: <n>, PASSED: <x>, FAILED: <y>`
- each test case emits one detail line (`PASS [...] ...` or `FAIL [...] ...`)

Note:

- A transient `osascript ... error -1763` line can appear during run output in this environment.
- The authoritative outcome is still the explicit `PASS:`/`FAIL:` summary line and runner exit code.

## Typical Failure Modes

- `No database found with exact name: ...`
  - `databaseName` does not match the DEVONthink database exactly.
- `compiled script not found: ...`
  - expected `.scpt` is missing at `tests/classifyRecords/testcase-04-classifyrecords.scpt`.
- `source script not found: ...`
  - `--compile` was used and the configured source path is missing.
- `JSON file not found: ...`
  - expected JSON config is missing at `Configuration/tests/testcase-04-classifyrecords-cases.json`.
- `Failed to parse JSON file ...`
  - JSON syntax is invalid.
- `Invalid JSON schema ...`
  - root is not an array, array is empty, object shape is invalid, or required fields are missing/empty.
- `No record found in database '...' for filename '...' (lookup name: '...').`
  - no record name matches the extension-stripped lookup name in that database.
- `Multiple records found ...`
  - lookup name is not unique in the selected database.
- `Found record by name '...', but filename differs ...`
  - name match succeeded, but the matched record does not have the expected filename with extension.
- `Precondition failed: Year/Month/Day dimension is already set.`
  - fixture record is not in the required initial state for the pilot scenario.
- cleanup/restore errors when setting tags
  - DEVONthink record state cannot be reset to the captured original tag list.
- Apple Event / environment errors (for example `Connection invalid`, `-1708`, `-1728`)
  - host process lacks stable automation access to DEVONthink.

## Extending the Test

To add more cases, append entries to `Configuration/tests/testcase-04-classifyrecords-cases.json` with:

- the same `databaseName`/`recordFilename` keys,
- a new `scenarioId`.

Then implement the scenario branch in `runScenarioById`.

Keep each scenario deterministic:

- explicit fixture identity,
- explicit preconditions,
- explicit postconditions,
- mandatory runtime trace assertions.

## Internal Structure

- `runTestCase(...)`: orchestration (resolve fixture, execute scenario, cleanup, result aggregation).
- `runScenarioById(...)`: scenario dispatcher.
- `TestLib.loadTestCase04Cases(...)`: testcase-specific wrapper around generic `loadTestCases(...)`.
- `TestLib.findRecordByFilenameInDatabase(...)`: shared deterministic record resolution and filename verification.
- `TestLib.runWithCleanup(...)`: shared cleanup execution for success and failure paths.
- `TestLib.runCasesWithSummary(...)`: shared testcase loop + result aggregation.
- `TestLib.validateClassifyRecordsTraceMetrics(...)`: centralized trace-metric checks for `classifyRecords`.
