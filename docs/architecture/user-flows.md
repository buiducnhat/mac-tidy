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

## Applications Flow

1. `AppSceneState` routes `Applications` actions to `ApplicationsStore`.
2. `ApplicationsStore.scanApplications()` asks `InstalledApplicationScanner` for local `.app` bundles under `/Applications`, `/System/Applications`, and `~/Applications` when present.
3. Selecting an app asks `ApplicationDataScanner` for a review list containing the app bundle plus conservative user Library matches.
4. `ApplicationsStore` caches each app's review list after the first detail scan, so returning to the same app does not rescan related data.
5. Related data candidates are review-only and unselected by default.
6. `ApplicationsStore.uninstallSelectedItems()` passes selected URLs to `CleanupService`, so app uninstall uses the same Finder Trash and safety refusals as cleanup.

## Homebrew Flow

1. Homebrew destinations route to `BrewStore`.
2. `refreshAll()` concurrently loads installed formulae, casks, outdated packages, and taps.
3. `BrewClient` executes `brew` commands with auto-update hints disabled, then parses command output into typed models.
4. Search, install, uninstall, upgrade, and maintenance commands reuse the same command runner and refresh package state after completion.
5. Errors are surfaced as lightweight UI banners instead of crashing the window flow.
