# Phase 04: Safety Polish, Tests, and Release Readiness

## Objective

- Harden the MVP for local use by improving safety diagnostics, permission handling, settings, tests, build scripts, and manual QA evidence.

## Scope

- Files/modules this phase may touch:
  - Settings and preferences views/stores.
  - Permission diagnostics and protected path messaging.
  - Shared UI polish in module views and Dashboard.
  - Test targets and fixtures.
  - Build/run scripts and lightweight documentation.
  - `SUMMARY.md` progress, discoveries, decisions, and outcomes.
- Files/modules this phase must not touch:
  - No new major features beyond MVP scope.
  - No privileged helper or background agent.
  - No broad refactor unrelated to safety or verification.

## Preconditions

- Phases 1-3 are complete.
- App can scan and move fixture items to Trash.

## Tasks

1. Context: review all MVP paths where file operations occur and list safety checks already in place.
2. Implement: add Settings controls for scan roots, excluded paths, showing protected items, and default selection policy if not already present.
3. Implement: add clear permission diagnostics for inaccessible paths, including guidance to choose a folder or grant access where appropriate.
4. Implement: add user-facing result states: scan complete, scan cancelled, no candidates, partial failures, cleanup complete.
5. Implement: add `OSLog` categories for scan and cleanup without logging excessive sensitive path details.
6. Implement: add keyboard/menu/toolbar affordances for rescan, cancel scan, reveal in Finder, and clean selected where appropriate.
7. Implement: review UI text to ensure it does not promise that all candidates are safe; risk labels must remain visible near actions.
8. Verify: expand tests for path normalization, protected paths, symlink handling, parent/child de-duplication, rule matching, and cleanup refusal.
9. Verify: run full build and test suite.
10. Verify: manually test app flows on temporary fixtures and at least one real read-only scan root without cleanup.
11. Implement: add a short README or local usage note if the workspace still has none.
12. Confirm: complete `SUMMARY.md` outcomes/retrospective with final verification and follow-ups.

## Acceptance Criteria

- User-visible or system-observable result:
  - App feels like a native Mac utility with stable sidebar, clear settings, responsive scans, visible safety labels, and explicit cleanup confirmation.
  - Permission failures and partial cleanup failures are understandable.
  - User can operate the MVP without touching unsupported privileged features.
- Required changed files:
  - Settings, diagnostics, tests, README/usage note if missing.
- Required unchanged behavior:
  - No full Mole parity creep.
  - No permanent delete.
  - No system optimize/status/touchid implementation.

## Verification

- Commands:
  - `swift test` or selected test command
  - `swift build` or selected build command
  - `scripts/build_and_run.sh`
  - `git status --short`
- Expected results:
  - Tests pass.
  - Build succeeds.
  - App launches and all MVP flows work in manual QA.
  - Git status shows only intended project files and plan/doc updates.
- Evidence to record in `SUMMARY.md`:
  - Final command results.
  - Manual QA checklist summary.
  - Known limitations and recommended follow-ups.

## Idempotence and Recovery

- Safe to re-run:
  - Tests, builds, fixture scans, fixture cleanup.
- Recovery if interrupted:
  - Resume from the failed checklist item and update `SUMMARY.md`.
- Rollback notes:
  - If a safety issue is found late, disable the risky action in UI before shipping and document the follow-up.

## Exit Criteria

- [ ] Settings and diagnostics are complete for MVP.
- [ ] Safety labels and confirmation flows are clear.
- [ ] Full tests pass.
- [ ] Build/run succeeds.
- [ ] Manual QA evidence is recorded.
- [ ] `SUMMARY.md` outcomes/retrospective is completed.
