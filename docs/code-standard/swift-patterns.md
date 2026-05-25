# Swift Patterns

## State And Concurrency

- UI-facing stores use `@Observable` and are annotated with `@MainActor`.
- Long-running scan and command work is pushed off the main thread with `Task` or `Task.detached`.
- Stores cancel prior tasks before starting a new scan to avoid stale results replacing current state.

## Filesystem Safety

- Normalize paths with `standardizedFileURL` before comparison or mutation.
- Gate filesystem work through `ProtectedPathRules` and `ScanRootRules` instead of open-coded path checks.
- Refuse symlinks and protected system paths for cleanup operations.
- Prefer returning typed diagnostics and result models instead of throwing UI-only strings through view code.

## Module Boundaries

- Shared filesystem logic belongs in `MacTidyCore` (`Models`, `Rules`, `Services`, `Support`).
- SwiftUI views and app-scoped orchestration stay in `App`, `Stores`, and `Views`.
- Add new cleanup behaviors by extending rules or services first, then surfacing them through stores.

## Naming

- Types are noun-based (`ScanStore`, `CleanupService`, `ProtectedPathRules`).
- Methods are verb-based and reflect the user action or side effect (`scan`, `cleanSelected`, `refreshAll`, `runUtility`).
- Sidebar and cleanup feature names should stay aligned between enum cases, views, and docs.
