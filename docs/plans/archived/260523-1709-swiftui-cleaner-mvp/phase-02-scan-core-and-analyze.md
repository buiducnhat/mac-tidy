# Phase 02: Scan Core and Analyze

## Objective

- Implement the non-destructive scan engine, core data models, safety rules, summaries, cancellation, and an Analyze view that can scan user-owned roots without freezing the UI.

## Scope

- Files/modules this phase may touch:
  - `Models/ScanItem.swift`, `Models/ScanCategory.swift`, `Models/RiskLevel.swift`, `Models/ScanRoot.swift`, `Models/ScanSummary.swift`.
  - `Rules/ProtectedPathRules.swift`, `Rules/ScanRootRules.swift`.
  - `Services/ScanService.swift`, `Services/PermissionDiagnosticsService.swift`.
  - `Stores/ScanStore.swift` or equivalent.
  - `Views/AnalyzeView.swift`, `Views/DashboardView.swift`.
  - `Support/ByteFormatter.swift`, `Support/PathDisplay.swift`, logging helpers.
  - `Tests/` for scan and rule behavior.
- Files/modules this phase must not touch:
  - Cleanup/delete/Trash action implementation except placeholder disabled controls.
  - Privileged system paths or sudo flow.

## Preconditions

- Phase 1 is complete and the app builds/runs.
- Sidebar and placeholder Analyze view exist.

## Tasks

1. Context: inspect scaffolded app structure and state ownership before adding services.
2. Implement: define value models for scan items, categories, risk levels, cleanup policy, scan roots, and scan summary.
3. Implement: add protected path rules that block known system paths and path traversal.
4. Implement: add scan root defaults for user-owned paths such as Home, Downloads, Desktop, Documents, and Library Caches when accessible.
5. Implement: build an async `ScanService` that enumerates directories off the main actor.
6. Implement: skip symlinks by default or resolve them and enforce root containment.
7. Implement: collect size, last modified date, kind, and permission errors as item-level diagnostics.
8. Implement: add cancellation and progress state to the scan store.
9. Implement: render Analyze results with sorting by size, category/risk labels, selected root display, progress, cancel, and rescan.
10. Implement: update Dashboard to show last scan summary or empty state.
11. Verify: add unit tests using temporary fixture directories for scan size, protected path blocking, symlink behavior, and permission-error handling where practical.
12. Verify: run build and tests.
13. Confirm: record scan performance notes and any permission limitations in `SUMMARY.md`.

## Acceptance Criteria

- User-visible or system-observable result:
  - User can start and cancel an Analyze scan from the app.
  - Results show path/name, size, category, risk, and diagnostics.
  - UI remains responsive while scanning.
- Required changed files:
  - Core models, scan service, scan store, Analyze view, tests.
- Required unchanged behavior:
  - No files are moved, deleted, or modified during scanning.

## Verification

- Commands:
  - `swift test` or selected test command
  - `swift build` or selected build command
  - `scripts/build_and_run.sh`
- Expected results:
  - Tests pass.
  - Build succeeds.
  - Manual scan can start, show progress/results, and cancel.
- Evidence to record in `SUMMARY.md`:
  - Test command result.
  - Manual scan root used and observed behavior.

## Idempotence and Recovery

- Safe to re-run:
  - Scans, tests, and builds.
- Recovery if interrupted:
  - Restart app and rescan; no persistent mutation should be required.
- Rollback notes:
  - If scanner performance is poor, reduce default roots and add stricter traversal depth before widening scope.

## Exit Criteria

- [ ] Scan models exist.
- [ ] Protected path rules exist.
- [ ] Analyze scan runs asynchronously.
- [ ] Cancel works.
- [ ] Tests pass.
- [ ] `SUMMARY.md` progress and discoveries are updated.
