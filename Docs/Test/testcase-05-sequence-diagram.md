# Testcase 05 Sequence Diagram (Reduced)

```mermaid
sequenceDiagram
    autonumber
    participant TC05 as testcase-05-updaterecordsmetadata.scpt
    participant TestLib as TestLib.scpt
    participant DocLib as DocLibrary.scpt
    participant BaseLib as BaseLibrary.scpt

    rect rgb(240, 248, 255)
        Note over TC05,TestLib: Setup and testcase orchestration
        TC05->>TestLib: runCasesWithSummary(...)
        TestLib->>TC05: runTestCase(...)
        Note over TC05,TestLib: Shared JSON loading, fixture lookup, and summary are shown in the overview diagram.
    end

    rect rgb(245, 255, 245)
        Note over TC05,DocLib: Scenario execution path
        TC05->>DocLib: initializeDatabaseConfiguration(...)
        DocLib->>BaseLib: getDEVONthinkRuntimeInfo(...)
        DocLib->>BaseLib: loadConfiguration(...)
        DocLib->>BaseLib: resolveDimensionsCachePath(...)
        DocLib->>BaseLib: dimensionsCacheExists(...)
        DocLib->>BaseLib: readDimensionsCache(...)

        TC05->>DocLib: fieldsFromTags(...)
        TC05->>DocLib: replaceDimensionPlaceholders(...)
        TC05->>TestLib: runWithCleanup(...)
        TestLib->>TC05: runScript.execute()
        TC05->>DocLib: updateRecordsMetadata(...)
    end

    rect rgb(255, 248, 240)
        Note over TC05,TestLib: Cleanup and result aggregation
        TestLib->>TC05: cleanupScript.execute()
        TC05->>TestLib: restoreRecordTags(...)
        TestLib-->>TC05: PASS/FAIL summary
    end
```
