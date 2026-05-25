# Targets And Directories

## Entry Points

- `Package.swift` defines all SwiftPM targets and excludes the non-source folders from compilation.
- `App/MacTidyApp.swift` is the application entry point.
- `Tests/MacTidyTests/TestRunner.swift` is the executable test entry point.
- `script/build_and_run.sh` builds and launches the unsigned app bundle.
- `script/package_release.sh` builds the bundle and zips a release artifact.

## Source Layout

- `App/` contains the app scene definition and AppKit bridge for activation behavior.
- `Views/` contains SwiftUI screens, subviews, sidebar composition, and Homebrew-specific surfaces.
- `Stores/` contains observable state owners for window navigation and task orchestration.
- `Stores/Homebrew/` contains Homebrew models, formatters, metadata resolvers, and the command client.
- `Models/` contains shared domain models such as scan items, summaries, cleanup results, and sidebar destinations.
- `Rules/` contains policy helpers for scan roots, cleanup eligibility, and protected paths.
- `Services/` contains filesystem traversal, cleanup execution, Finder integration, and diagnostics helpers.
- `Support/` contains low-level helpers such as logging, path display, byte formatting, and resource assets.
- `Tests/MacTidyTests/` contains focused coverage for scan rules and cleanup behavior.

## Non-Source Repository Areas

- `dist/` contains the generated `.app` bundle and release archives.
- `docs/` contains maintained project documentation plus archived planning material.
- `.agents/` and `.codex/` hold local agent configuration and are excluded from targets.
