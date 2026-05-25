# Implementation Plan: SwiftUI Mac Cleaner MVP

> Created: 2026-05-23 17:09:00

## Purpose / Big Picture

- Build a native macOS SwiftUI MVP inspired by Mole's most useful cleanup workflows: analyze disk usage, review safe cleanup candidates, purge project artifacts, and remove installer files.
- The MVP should prioritize Mac-native UX, safety, and review-first deletion over full Mole feature parity.
- Brainstorm context came from the current chat; no persisted brainstorm artifact was requested.

## Objective

- Scaffold a new macOS SwiftUI app in this empty workspace and implement a safe, review-first cleaner MVP.
- The app should let users scan selected user-owned locations, inspect large or cleanable items, and move selected cleanup candidates to Trash.

## Context and Orientation

- Relevant docs loaded:
  - `cobrew:brainstorm` skill: requirements discovery and design framing.
  - `cobrew:write-plan` skill: implementation plan artifact format.
  - `.agents/skills/swiftui-patterns/SKILL.md`: macOS SwiftUI scene/layout/file-structure guidance.
  - `.agents/skills/appkit-interop/SKILL.md`: small AppKit bridges for platform gaps.
- Relevant files/modules:
  - Workspace currently has no app source files, no `docs/`, and is not a git repository.
  - Existing `.agents/commands/` contains macOS build/run helper command docs only.
- Existing patterns to follow:
  - Use a non-trivial macOS app structure: `App/`, `Views/`, `Models/`, `Stores/`, `Services/`, `Support/`.
  - Use `NavigationSplitView`, native sidebar rows, toolbars, Settings scene, semantic colors, and explicit state ownership.
  - Use AppKit only for small platform edges such as Finder reveal, Trash operations if needed, and settings/system permission links.
- Constraints, dependencies, and compatibility notes:
  - SwiftUI app was chosen over CLI.
  - MVP must avoid privileged system mutations: no sudo helper, no PAM/Touch ID changes, no deep optimize.
  - Sandbox and Full Disk Access are major product constraints. Initial MVP should scan user-selected or user-owned paths and handle permission failures gracefully.
  - Cleanup should default to moving items to Trash, not permanent deletion.

## Scope

### In scope

- New SwiftUI macOS app scaffold with a main window and Settings scene.
- Sidebar modules: Dashboard, Analyze, Clean, Purge, Installers, Settings access.
- Core scan engine for user-owned roots such as Home, Downloads, Desktop, Documents, and selected cache/project paths.
- Rule-based scan candidates:
  - Safe caches: known user cache folders and app/developer cache candidates.
  - Project artifacts: `node_modules`, `.build`, `DerivedData`, `target`, `dist`, `.next`, `Pods`, `Carthage/Build`.
  - Installer files: `.dmg`, `.pkg`, `.mpkg`, `.iso`, `.xip`, and optionally installer-like `.zip`.
- Review UI with selection, size summaries, risk labels, reveal in Finder, and move to Trash.
- Tests for scanner rules, path safety, parent/child de-duplication, and non-destructive cleanup behavior.

### Out of scope

- Full Mole feature parity.
- CLI subcommands.
- Realtime status dashboard for CPU/GPU/network/battery.
- System optimize actions, launchctl changes, database rebuilds, sudo/PAM Touch ID configuration.
- Permanent delete by default.
- Background auto-clean, startup agent, privileged helper, or scheduled cleanup.
- Scanning or deleting protected system directories such as `/System`, `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`, `/etc`, and `/var/db`.

## Architecture & Approach

- Create a Swift Package or Xcode-backed macOS app with clear module boundaries:
  - `App/`: `@main` app, scenes, app delegate if required.
  - `Models/`: `ScanItem`, `ScanCategory`, `RiskLevel`, `CleanupPolicy`, `ScanRoot`, `ScanSummary`.
  - `Stores/`: observable app state, scan session state, user preferences.
  - `Services/`: scan service, cleanup service, permission diagnostics, Finder/platform service.
  - `Rules/`: cleanup rules for caches, purge artifacts, installers, and protected paths.
  - `Views/`: split root, sidebar, dashboard, analyze, clean review, purge, installers, settings.
  - `Support/`: byte formatting, path display, logging, filesystem helpers.
- Keep SwiftUI as the source of truth. Services expose async APIs and return value models.
- Use `FileManager` and resource values for filesystem traversal. Add bounded concurrency and cancellation before broad scans.
- Use Trash-first cleanup. Prefer `FileManager.trashItem(at:resultingItemURL:)` when sufficient; use small AppKit/Finder bridge only where SwiftUI/Foundation cannot provide expected macOS behavior.
- Treat scan failures as item-level diagnostics, not app-level crashes.

## Progress

- [x] Plan approved for execution.
- [x] Phase 1 complete.
- [x] Phase 2 complete.
- [x] Phase 3 complete.
- [x] Phase 4 complete.
- [x] Final verification complete.
- 2026-05-23 17:22:51 +07 — Started Phase 1. Verified the workspace was not inside a git repository and initialized git at the workspace root.
- 2026-05-23 17:24:58 +07 — Completed Phase 1 with a SwiftPM macOS 14 SwiftUI GUI app scaffold. Verification passed: `swift build`; `script/build_and_run.sh --verify`; `osascript` observed one `MacTidy` window. Changed files: `Package.swift`, `.gitignore`, `.codex/environments/environment.toml`, `script/build_and_run.sh`, app/view/model/store scaffold files, empty service/rule/support folders, and scaffold test target.
- 2026-05-23 17:25:08 +07 — Started Phase 2. Existing scaffold uses root-owned `AppSceneState` and split detail views, with feature behavior still isolated behind placeholders.
- 2026-05-23 17:29:47 +07 — Completed Phase 2. Verification passed: `swift build`; `swift run MacTidyCoreTests`; `script/build_and_run.sh --verify`; `osascript` observed one `MacTidy` window. Implemented `MacTidyCore` models/rules/services/support, async scan service, protected path checks, symlink skipping, scan store, Analyze results table, Dashboard summary, and fixture-based scan/rule tests. Manual scan behavior was exercised through temporary fixture tests; UI launch and controls were verified by build/launch checks.
- 2026-05-23 17:30:05 +07 — Started Phase 3. Cleanup candidates will reuse `ScanItem` with `category`, `risk`, and `cleanupPolicy` metadata instead of adding a separate action model.
- 2026-05-23 17:32:37 +07 — Completed Phase 3. Verification passed: `swift build`; `swift run MacTidyCoreTests`; `script/build_and_run.sh --verify`; `osascript` observed one `MacTidy` window. Implemented Clean/Purge/Installer rules, candidate scanner, conservative default selection, shared review UI, Finder reveal, parent/child selection de-duplication, protected/symlink/missing-item cleanup refusals, and Trash-first cleanup. Fixture Trash behavior verified by moving a temporary test file to Finder Trash and confirming it left its original location.
- 2026-05-23 17:32:48 +07 — Started Phase 4. Current file-operation safety checks: scan roots require readable non-protected directories; scanner skips symlinks and protected paths; cleanup collapses parent/child selections and refuses protected paths, symlinks, and missing items before Trash.
- 2026-05-23 17:34:23 +07 — Completed Phase 4. Verification passed: `swift build`; `swift run MacTidyCoreTests`; `script/build_and_run.sh --verify`; `osascript` observed one `MacTidy` window; `git status --short --branch` showed only intended new project, docs, and plan files in the new repository. Added Settings safety controls, excluded root filtering, visible scan diagnostics, result states, OSLog scan/cleanup categories, menu/keyboard actions, README usage notes, and expanded cleanup tests.
- 2026-05-23 17:34:49 +07 — Final verification passed: `swift build`; `swift run MacTidyCoreTests`; `script/build_and_run.sh --verify`; `osascript` observed one `MacTidy` window; `git status --short --branch`. Note: because git was initialized during Phase 1, pre-existing `.agents/` and plan docs are untracked alongside the new app files until the first commit.

## Phases

- [x] **Phase 1 [M]: Scaffold SwiftUI app shell** — Create the app structure, scene model, root navigation, placeholder modules, settings, and build/run scripts.
- [x] **Phase 2 [L]: Implement scan core and Analyze** — Add models, rules, scanner, cancellation, summaries, and an Analyze view for user-owned roots.
- [x] **Phase 3 [L]: Implement Clean, Purge, Installers, and Trash flow** — Add cleanup candidate rules, selection/de-duplication, review UI, Finder reveal, and move-to-Trash.
- [x] **Phase 4 [M]: Safety polish, tests, and release readiness** — Add tests, diagnostics, permission handling, UX polish, and final verification.

## Key Changes

- Files/modules likely to change:
  - New app/package files at the workspace root.
  - `App/`, `Views/`, `Models/`, `Stores/`, `Services/`, `Rules/`, `Support/`.
  - `Tests/` for core scanning and cleanup behavior.
  - `scripts/build_and_run.sh` and `.codex/environments/environment.toml` if following local run-button conventions.
- Data/API/schema impacts:
  - New internal model schema for scan results and cleanup policies.
  - User preferences persisted via `@AppStorage` or a small preferences store.

## Validation and Acceptance

- Lint/typecheck/tests/build commands:
  - `swift build` or `xcodebuild` depending on scaffold choice.
  - `swift test` for SwiftPM test targets if using package-first structure.
  - App launch via local build/run script.
- Manual checks:
  - App opens to a native macOS window with stable sidebar selection.
  - Analyze scan can run, cancel, and show item sizes without freezing UI.
  - Clean/Purge/Installer candidates are labeled by risk and default-selected conservatively.
  - Move-to-Trash only affects selected fixture/test items during QA.
  - Permission denied paths show diagnostics, not crashes.
- Observable acceptance criteria:
  - A user can scan supported roots, review candidates, reveal items in Finder, and move selected safe candidates to Trash.
  - No destructive action occurs without explicit confirmation.
  - Protected paths are blocked by policy.

## Idempotence and Recovery

- Safe re-run notes:
  - Scans should be repeatable and cancellable.
  - App scaffolding phase should avoid overwriting user-created files if interrupted and resumed.
  - Tests must use temporary fixtures, not real user data.
- Rollback/recovery notes:
  - Cleanup operations move to Trash; user can recover through Finder Trash.
  - App source changes can be reverted via git once repository is initialized.
- Irreversible operations or destructive steps:
  - None planned for MVP. Permanent deletion is out of scope.

## Dependencies

- `swift-argument-parser` is not needed because SwiftUI app was selected over CLI.
- No third-party UI dependencies are required for MVP.
- Optional: Xcode project generation or SwiftPM app structure, chosen during Phase 1 based on fastest reliable local build path.

## Risks & Mitigations

- Risk: macOS permissions block scans in important folders -> mitigation: start with user-owned roots, expose permission diagnostics, and allow user-selected roots.
- Risk: accidental deletion of important user data -> mitigation: Trash-first, risk labels, protected path rules, confirmation sheet, no auto-clean.
- Risk: UI freezes on large directories -> mitigation: async scanner, cancellation, progress state, bounded traversal, no broad synchronous scan on main actor.
- Risk: double-counting parent/child selections -> mitigation: normalize selected paths and collapse children under selected parents before computing totals or cleanup actions.
- Risk: symlink traversal escapes scan roots -> mitigation: skip symlinks by default or resolve and enforce root containment.
- Risk: SwiftUI app grows into one large view -> mitigation: follow `swiftui-patterns` structure and split views/services from the start.

## Surprises & Discoveries

- 2026-05-23 17:29:47 +07 — Local Swift toolchain exposes neither `XCTest` nor Swift Testing to `swift test`, so tests are run through a selected SwiftPM executable command: `swift run MacTidyCoreTests`.
- 2026-05-23 17:29:47 +07 — The SF Symbol `externaldrive.badge.magnifyingglass` is unavailable in this environment and prevented the main window from staying open; replaced it with `magnifyingglass.circle`.

## Decision Log

- 2026-05-23 17:09:00 — Decision: Build a SwiftUI app MVP instead of CLI-first. Rationale: user selected native app direction after comparing CLI, SwiftUI, and hybrid approaches.
- 2026-05-23 17:09:00 — Decision: Exclude privileged optimize/status/touchid features from MVP. Rationale: they add high safety and permission risk without being necessary for first user value.
- 2026-05-23 17:29:47 +07 — Decision: Split scan models/rules/services into `MacTidyCore`. Rationale: SwiftPM rejected overlapping source files across app and test runner targets, and a core library keeps behavior testable without duplicating sources.
- 2026-05-23 17:29:47 +07 — Decision: Allow any readable, non-protected directory as a scan root. Rationale: user-selected and temporary fixture roots can be safe without living under Home; protected system prefixes remain blocked.

## Outcomes & Retrospective

- Result: Completed with follow-ups.
- Verification summary: `swift build`, `swift run MacTidyCoreTests`, and `script/build_and_run.sh --verify` passed; app launch was confirmed with one visible `MacTidy` window through System Events.
- Delivered a SwiftPM macOS 14 SwiftUI app with Dashboard, Analyze, Clean, Purge, Installers, Settings, async scanning, rule-based candidates, Finder reveal, Trash-first cleanup, protected path safeguards, symlink refusal, parent/child de-duplication, and local run-button support.
- Deviations: `swift test` was replaced by the selected command `swift run MacTidyCoreTests` because the local Swift toolchain exposes neither `XCTest` nor Swift Testing.
- Follow-ups: integrate excluded paths deeper into recursive scanners, add folder picker support for custom roots, add richer UI-level automated QA, and decide distribution/signing model.

## Open Questions

- Minimum supported macOS version must be chosen before implementation. Recommended default: current development machine target or macOS 14+ unless the user requires older support.
- Distribution model is not yet decided: local/dev-only, unsigned personal app, Developer ID signed app, or sandboxed App Store-style app.
