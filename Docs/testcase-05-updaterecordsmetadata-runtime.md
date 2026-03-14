# Testcase 05: updateRecordsMetadata Name and Comments Check

## Purpose

This test validates `updateRecordsMetadata` for one explicitly identified fixture record.
It focuses on the regular record flow where both name and comments are updated.

It covers:

- deterministic fixture lookup by exact `databaseName` and exact `recordFilename`,
- scenario behavior for `pilot-name-comments`,
- strict precondition checks for configuration and date tags,
- full cleanup of changed record state (tags, name, comments, relevant custom metadata).

See also:

- Sequence diagram: `Docs/testcase-05-sequence-diagram.md`

## Files

- Source: `src/tests/updateRecordsMetadata/testcase-05-updaterecordsmetadata.applescript`
- Compiled script: `tests/updateRecordsMetadata/testcase-05-updaterecordsmetadata.scpt`
- Shared runner: `scripts/run-testcase.sh`
- Wrapper runner: `scripts/run-testcase-05.sh`
- Test utility library (source): `src/Libs/TestLib.applescript`
- Test utility library (compiled): `Libs/TestLib.scpt`
- Test case config: `Configuration/tests/testcase-05-updaterecordsmetadata-cases.json`
- Production handler under test: `src/Libs/DocLibrary.applescript` (`updateRecordsMetadata`)

## Test Data Contract

Test cases are loaded from:

- `Configuration/tests/testcase-05-updaterecordsmetadata-cases.json`

JSON schema (top-level array):

```json
[
  {
    "databaseName": "<exact database name>",
    "recordFilename": "<exact filename.ext>",
    "scenarioId": "pilot-name-comments"
  }
]
```

Rules:

- `databaseName` must exactly match a DEVONthink database name.
- `recordFilename` must include an extension.
- lookup name is derived from `recordFilename` by removing the last extension segment.
- record resolution is name-based and then validated by exact filename (`DTfe`).
- top-level JSON value must be a non-empty array.
- each required field must be a non-empty string.

## Scenario: `pilot-name-comments`

For the resolved record, the test performs:

1. Initialize database configuration (`initializeDatabaseConfiguration`).
2. Validate preconditions:
   - `pNameTemplate` is configured.
   - `pCommentsFields` is not empty.
   - `pDateDimensions` contains exactly three dimensions.
   - all configured date dimensions are present in the record tags.
3. Compute expected name from `pNameTemplate` using `replaceDimensionPlaceholders`.
4. Capture original state for cleanup:
   - tags,
   - name,
   - comments,
   - relevant custom metadata fields (`pCustomMetadataFields ∪ pCommentsFields`).
5. Set sentinel values for name/comments.
6. Execute `updateRecordsMetadata({theRecord})`.
7. Assert:
   - sentinel name was overwritten,
   - sentinel comment was overwritten,
   - resulting name matches the expected template output,
   - resulting comment matches reconstruction from `pCommentsFields` using production join logic.
8. Cleanup on both success and failure paths:
   - restore tags,
   - restore custom metadata,
   - restore name and comments.

## Execution

Recommended (wrapper runner):

```bash
./scripts/run-testcase-05.sh
```

Compile + run from source in one command:

```bash
./scripts/run-testcase-05.sh --compile
```

The wrapper delegates to `scripts/run-testcase.sh`, which supports:

- running an already compiled `.scpt`,
- optional compile-before-run via `--compile` (requires the configured `--source` path).

Manual run (compiled script only):

```bash
osascript "tests/updateRecordsMetadata/testcase-05-updaterecordsmetadata.scpt"
```

Exit codes (`run-testcase-05.sh`):

- `0`: test passed
- `1`: test failed
- `2`: execution/infrastructure error

Result format:

- success: `PASS: TOTAL: <n>, PASSED: <n>, FAILED: 0`
- failure: `FAIL: TOTAL: <n>, PASSED: <x>, FAILED: <y>`

## Typical Failure Modes

- `No database found with exact name: ...`
- `No record found in database ...`
- `Multiple records found ...`
- `Found record by name ..., but filename differs ...`
- `JSON file not found: ...`
- `source script not found: ...`
  - `--compile` was used and the configured source path is missing.
- `Failed to parse JSON file ...`
- `Invalid JSON schema ...`
- `Precondition failed: Year/Month/Day dimension is missing.`
- `pNameTemplate must be configured for this test.`
- `pCommentsFields must not be empty for this test.`
- cleanup failures when restoring tags/custom metadata/name/comments.

## Internal Structure

- `runTestCase(...)`: testcase-specific orchestration and metadata-state snapshot.
- `runScenarioById(...)`: scenario dispatcher.
- `TestLib.loadTestCase05Cases(...)`: testcase-specific wrapper around generic `loadTestCases(...)`.
- `TestLib.findRecordByFilenameInDatabase(...)`: shared deterministic record resolution and filename verification.
- `TestLib.runWithCleanup(...)`: shared cleanup execution for success and failure paths.
- `TestLib.runCasesWithSummary(...)`: shared testcase loop + result aggregation.
