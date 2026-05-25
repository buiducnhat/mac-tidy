# Phase 01: Scaffold SwiftUI App Shell

## Objective

- Create a buildable native macOS SwiftUI app scaffold with explicit app structure, scene model, sidebar navigation, placeholder module views, settings, and local build/run support.

## Scope

- Files/modules this phase may touch:
  - Workspace root app/package/project files.
  - `App/`, `Views/`, `Models/`, `Stores/`, `Services/`, `Rules/`, `Support/`.
  - `Tests/` only for empty target scaffolding if needed.
  - `scripts/build_and_run.sh`.
  - `.codex/environments/environment.toml`.
- Files/modules this phase must not touch:
  - No cleanup implementation.
  - No real filesystem deletion logic.
  - No privileged helper, launch agent, sudo, or system configuration files.

## Preconditions

- The workspace remains empty except `.agents/` and this plan.
- The user has approved the plan for execution.
- Xcode and Swift toolchain are available locally.

## Tasks

1. Context: verify whether the workspace is inside a git repository with `git rev-parse --is-inside-work-tree`.
2. Context: if not in a git repository, initialize one at the workspace root.
3. Implement: choose the fastest reliable scaffold path for a macOS SwiftUI app. Prefer SwiftPM if it can build and run the app cleanly; otherwise create an Xcode project.
4. Implement: create folder structure for `App/`, `Views/`, `Models/`, `Stores/`, `Services/`, `Rules/`, `Support/`.
5. Implement: create `@main` app with `WindowGroup` primary scene and a dedicated `Settings` scene.
6. Implement: create root `NavigationSplitView` with native sidebar rows for Dashboard, Analyze, Clean, Purge, and Installers.
7. Implement: add placeholder detail views with real toolbar/title structure but no fake cleanup behavior.
8. Implement: add a minimal observable app state or scene state for sidebar selection.
9. Implement: add `scripts/build_and_run.sh` and Codex run-button environment config following local app conventions.
10. Verify: build the app from command line.
11. Verify: run the app and confirm the main window opens.
12. Confirm: record scaffold choice, build command, and launch result in `SUMMARY.md`.

## Acceptance Criteria

- User-visible or system-observable result:
  - A native macOS app opens with a sidebar and placeholder module details.
  - Settings opens as a separate native Settings scene.
- Required changed files:
  - App scaffold files exist in clear directories.
  - Build/run script exists.
- Required unchanged behavior:
  - No cleanup or scan operation touches real user files.

## Verification

- Commands:
  - `git status --short --branch`
  - `swift build` or selected `xcodebuild` command
  - `scripts/build_and_run.sh`
- Expected results:
  - Build exits successfully.
  - App launches without runtime crash.
  - Main window and Settings scene are reachable.
- Evidence to record in `SUMMARY.md`:
  - Scaffold type, exact build command, and launch observation.

## Idempotence and Recovery

- Safe to re-run:
  - Build commands and launch script.
  - Folder creation if existing files are preserved.
- Recovery if interrupted:
  - Resume by checking which scaffold files exist and avoid overwriting user edits.
- Rollback notes:
  - If scaffold choice fails, document reason and switch scaffold strategy before adding feature logic.

## Exit Criteria

- [ ] App scaffold exists.
- [ ] Main window launches.
- [ ] Settings scene exists.
- [ ] Build/run script works.
- [ ] `SUMMARY.md` progress and decision log are updated.
