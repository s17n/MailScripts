# Performance Tracing

This document explains how runtime tracing works in `Logger.scpt` and what must be configured.

## How It Works

- Instrumented operations call `logger's trace(logCtx, "enter ...")` at start and `logger's trace(logCtx, "exit ...")` at end.
- The logger keeps an internal call stack and measures runtime with a monotonic clock (`systemUptime`).
- For each operation, the logger stores:
  - call count
  - inclusive total runtime
  - exclusive total runtime (child operation time is subtracted)
  - max exclusive runtime
- Most DEVONthink menu scripts start a clean run with `docLib's beginPerformanceTrace(...)` before calling a `DocLibrary` handler and print results with `docLib's finishPerformanceTrace(...)` after the handler returns.
- `classifyRecords` and `updateRecordsMetadata` start and print their own trace run directly in `DocLibrary`, including when invoked from `/DEVONthink Menu`.

## Output

`logTraceMetrics()` writes **only to the file logger output** (not to DEVONthink log panel):

1. A totals line (first line), for example:
   - `totals: operations=23, calls=148, exclusive_total_ms=10296.119`
2. One line per operation, sorted by `exclusive_total_ms` (descending), for example:
   - `share_percent=37.4%, calls=12, exclusive_total_ms=145.237, avg_exclusive_ms=12.103, max_exclusive_ms=40.512, operation=createTagList`

Formatting details:

- `share_percent`: 1 decimal place and `%`
- Runtime values (`exclusive_total_ms`, `avg_exclusive_ms`, `max_exclusive_ms`): fixed 3 decimals (no scientific notation)

## Configuration

No dedicated tracing config file is required. Tracing uses existing logger/runtime settings:

- `pLogLevel` in `~/.mailscripts/config.scpt`
  - `2` (INFO) is sufficient to see totals and per-operation metric lines.
  - `0` (TRACE) additionally shows all trace enter/exit lines.
- `pLogFilePath` in `~/.mailscripts/config.scpt` (optional)
  - Performance-tracing output from `logTraceMetrics()` is written to this file.
  - If unset/empty, logger falls back to `/tmp/mailscripts.log`.

Runtime toggle (optional):

- `logger's setTraceMetricsEnabled(true|false)` enables/disables metric aggregation.
