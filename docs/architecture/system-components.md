# System Components

## Targets

- `MacTidyCore` contains the shared models, rules, support helpers, and filesystem-facing services.
- `MacTidy` contains the SwiftUI app, screen composition, and observable stores.
- `MacTidyCoreTests` is a custom executable test runner used instead of `swift test`.

This split keeps cleanup and scan logic reusable from the UI layer while avoiding SwiftUI dependencies in core code.

## Runtime State Graph

- `App/MacTidyApp.swift` starts a single `AppSceneState` for the main window group.
- `Stores/AppSceneState.swift` owns navigation and long-lived store instances for scan, cleanup, and Homebrew surfaces.
- `ScanStore` manages analyze-mode roots, running state, summaries, and diagnostics.
- `CleanupStore` is instantiated once per cleanup module (`clean`, `purge`, `installers`) and tracks candidates, selection, and cleanup results.
- `BrewStore` manages Homebrew package lists, taps, search, command history, and active command output.

## Service Boundaries

- `Services/ScanService.swift` scans allowed roots, calculates sizes, and emits diagnostics for unreadable paths or capped results.
- `Services/CleanupCandidateScanner.swift` builds module-specific cleanup candidate lists from configured roots.
- `Services/CleanupService.swift` performs trash moves after applying path protection, existence, and symlink checks.
- `Services/FinderService.swift` reveals candidate items in Finder from the UI.
- `Services/PermissionDiagnosticsService.swift` converts filesystem failures into user-facing diagnostics.
- `Stores/Homebrew/BrewClient.swift` shells out to `brew`, normalizes output, and feeds parsed models back into `BrewStore`.

## Bundle And Resources

- `script/build_and_run.sh` builds the SwiftPM executable, assembles `dist/MacTidy.app`, copies `Support/Resources/` into `Contents/Resources`, and writes the bundle metadata.
- The app icon source is stored in `Support/Resources/AppIcon-1024.png` and packaged as `Support/Resources/AppIcon.icns`.
