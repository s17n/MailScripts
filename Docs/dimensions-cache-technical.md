# Dimensions Cache Technical Documentation

## Purpose

The dimensions cache stores flattened dimension/category data as JSON on the filesystem to avoid repeated expensive DEVONthink tag traversal during `initializeDimensions`.

## Design

The implementation is split by responsibility:

- `DocLibrary` owns DEVONthink-specific extraction of dimensions (`refreshDimensionsCache`).
- `BaseLibrary` owns generic filesystem and JSON cache operations.

This keeps cache transport logic reusable and prevents duplication in `DocLibrary`.

## Data Flow

1. `initializeDatabaseConfiguration` resolves `pDimensionsCachePath`.
2. `initializeDimensions` always reads from filesystem.
3. If the cache file does not exist, `refreshDimensionsCache` creates it.
4. If cache read/parsing fails, `refreshDimensionsCache` rebuilds and overwrites the file.
5. `pDimensionsDictionary` is loaded from the filesystem payload and used by downstream operations.

## Public Operations

### `updateDimensionsCache(theDatabaseName)`

Use this when dimensions/tags changed and the cache must be refreshed explicitly.

Behavior:

1. Resolves database object by name.
2. Initializes database configuration (including cache path).
3. Rebuilds dimensions from DEVONthink.
4. Writes the updated JSON cache file.

### Dedicated Command Script

A dedicated DEVONthink menu command script is available:

- `DEVONthink Menu/Update Dimensions Cache___Cmd-Ctrl-Shift-D.scpt`

Behavior:

1. Reads the current DEVONthink selection.
2. Resolves the target database name from the first selected record.
3. Calls `docLib's updateDimensionsCache(theDatabaseName)`.
4. Shows DEVONthink alert messages on errors.

Operational note:

- At least one record must be selected to resolve the target database.

### `refreshDimensionsCache(theDatabase)` (Internal)

Internal worker operation in `DocLibrary`:

- Reads dimensions from DEVONthink.
- Flattens categories.
- Delegates persistence to `BaseLibrary.writeDimensionsCache`.

## BaseLibrary Cache API

- `resolveDimensionsCachePath(configurationFile, theDatabaseName, theDatabaseConfigurationFolder)`
- `dimensionsCacheExists(cachePath)`
- `readDimensionsCache(cachePath)`
- `writeDimensionsCache(cachePath, dimensionsDictionary)`
- `sanitizeFilename(rawName)`

## Cache File Format

JSON object:

- `version` (integer)
- `updatedAt` (string timestamp)
- `dimensions` (object: `dimensionName -> [category1, category2, ...]`)

Example:

```json
{
  "version": 1,
  "updatedAt": "2026-03-11 21:00:00 +0100",
  "dimensions": {
    "04 Sender": ["Alice", "Bob"],
    "05 Subject": ["Invoice", "Travel"]
  }
}
```

## Configuration

Optional database configuration property:

```applescript
property pDimensionsCachePath : "/absolute/path/to/dimensions-mail.json"
```

If omitted, fallback path is:

`<pDatabaseConfigurationFolder>/cache/dimensions-<databaseName>.json`

## Error Handling

- Missing cache file: rebuilt automatically.
- Invalid or unreadable JSON: rebuilt automatically.
- Missing cache path configuration: explicit error.

## Refactoring Opportunities

1. Add cache freshness metadata (for example a DEVONthink-side signature) to avoid manual refresh.
2. Reduce recursive logging in `createTagList` to improve rebuild performance further.
3. Introduce a schema version migration handler when cache format evolves beyond `version = 1`.
