# Phase 03: Clean, Purge, Installers, and Trash Flow

## Objective

- Add MVP cleanup candidate modules for safe caches, project artifacts, and installer files, then implement review-first selection and move-to-Trash behavior.

## Scope

- Files/modules this phase may touch:
  - `Rules/CleanRules.swift`, `Rules/PurgeRules.swift`, `Rules/InstallerRules.swift`.
  - `Services/CleanupService.swift`, `Services/FinderService.swift`.
  - `Stores/CleanupStore.swift` or additions to existing scan store.
  - `Views/CleanView.swift`, `Views/PurgeView.swift`, `Views/InstallersView.swift`, shared review list components.
  - `Support/SelectionDeduper.swift`, path normalization helpers.
  - `Tests/` for rules, de-duplication, and Trash behavior using test fixtures or service fakes.
- Files/modules this phase must not touch:
  - No permanent delete.
  - No sudo, privileged helper, launchctl, PAM, or system optimize.
  - No automatic background cleanup.

## Preconditions

- Phase 2 is complete.
- Scan service can produce `ScanItem` results and risk metadata.
- App has placeholder Clean, Purge, and Installers views.

## Tasks

1. Context: inspect existing scan models and decide whether cleanup candidates reuse `ScanItem` directly or wrap it in a cleanup action model.
2. Implement: add Clean rules for safe user cache candidates and conservative default selection.
3. Implement: add Purge rules for project artifact names: `node_modules`, `.build`, `DerivedData`, `target`, `dist`, `.next`, `Pods`, `Carthage/Build`.
4. Implement: add Installer rules for `.dmg`, `.pkg`, `.mpkg`, `.iso`, `.xip`, and installer-like `.zip` if zip inspection can be implemented safely and cheaply.
5. Implement: add parent/child selection de-duplication so selected descendants are collapsed when a parent is selected.
6. Implement: add review UI shared by Clean/Purge/Installers with size total, selected count, risk labels, checkboxes, reveal in Finder, and confirmation sheet.
7. Implement: add `CleanupService` that moves selected URLs to Trash and reports per-item results.
8. Implement: ensure cleanup refuses protected paths, symlink escapes, missing paths, and parent/child duplicates.
9. Implement: add `FinderService` for reveal/open using a small AppKit or Foundation bridge.
10. Verify: add tests for rule matching, default selection, de-duplication, protected path refusal, and cleanup service with fakes or temp fixtures.
11. Verify: manually run cleanup only against temporary fixture paths, not real user data.
12. Confirm: record Trash behavior and any denied-item diagnostics in `SUMMARY.md`.

## Acceptance Criteria

- User-visible or system-observable result:
  - Clean/Purge/Installers modules scan and show candidates.
  - Safe items may be selected by default; review-required/user-data items require manual selection.
  - User can reveal candidates in Finder.
  - Confirmed cleanup moves selected allowed items to Trash and shows results.
- Required changed files:
  - Rule files, cleanup service, Finder service, module views, tests.
- Required unchanged behavior:
  - No permanent deletion.
  - No cleanup without explicit confirmation.
  - Protected paths remain blocked.

## Verification

- Commands:
  - `swift test` or selected test command
  - `swift build` or selected build command
  - `scripts/build_and_run.sh`
- Expected results:
  - Tests pass.
  - Build succeeds.
  - Manual fixture cleanup moves only selected allowed test items to Trash.
- Evidence to record in `SUMMARY.md`:
  - Test command result.
  - Fixture cleanup observation and any recovery notes.

## Idempotence and Recovery

- Safe to re-run:
  - Scans and tests.
  - Cleanup against fresh temp fixtures.
- Recovery if interrupted:
  - Rescan to reconcile moved/missing items.
  - Recover moved fixture items from Trash if needed.
- Rollback notes:
  - If Trash API behavior is unreliable, isolate platform behavior behind `CleanupService` and switch implementation without changing UI.

## Exit Criteria

- [ ] Clean rules exist and are conservative.
- [ ] Purge rules exist.
- [ ] Installer rules exist.
- [ ] Review UI is shared and functional.
- [ ] Move-to-Trash works on fixtures.
- [ ] Tests pass.
- [ ] `SUMMARY.md` progress and decisions are updated.
