# User Flows

## Analyze Flow

1. `AppSceneState` routes `Dashboard` and `Analyze` actions to `ScanStore.scan()`.
2. `ScanStore` filters out excluded paths from user defaults and rejects an empty selection.
3. `ScanService` scans readable, allowed roots on a detached task and returns items sorted by size.
4. The UI renders the returned `ScanItem` list, aggregated `ScanSummary`, and any diagnostics.

## Cleanup Flow

1. The sidebar destination selects one `CleanupStore` instance tied to a `CleanupModule`.
2. `CleanupStore.scan()` asks `CleanupCandidateScanner` for module-specific candidates from allowed roots.
3. Low-risk items with `trashAllowed` policy are selected by default when the corresponding preference is enabled.
4. `CleanupStore.cleanSelected()` passes the current selection to `CleanupService`.
5. `CleanupService` collapses nested selections, refuses protected or invalid paths, and moves accepted items to Finder Trash.

## Homebrew Flow

1. Homebrew destinations route to `BrewStore`.
2. `refreshAll()` concurrently loads installed formulae, casks, outdated packages, and taps.
3. `BrewClient` executes `brew` commands with auto-update hints disabled, then parses command output into typed models.
4. Search, install, uninstall, upgrade, and maintenance commands reuse the same command runner and refresh package state after completion.
5. Errors are surfaced as lightweight UI banners instead of crashing the window flow.
