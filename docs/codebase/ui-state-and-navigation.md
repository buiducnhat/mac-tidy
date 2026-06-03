# UI State And Navigation

## Navigation Model

- `SidebarDestination` is the central navigation enum for the whole app.
- The enum separates MacTidy cleanup views from Homebrew views and also exposes metadata for titles, subtitles, and SF Symbols.
- `RootView` binds the split-view selection directly to `AppSceneState.selectedDestination`.
- The `Applications` destination routes local `.app` inventory and uninstall review into `ApplicationsStore`.

## Store Ownership

- `AppSceneState` owns one `ScanStore`, three `CleanupStore` instances, one `ApplicationsStore`, and one `BrewStore`.
- The window-level state object decides which store receives toolbar actions such as rescan, cleanup, search, and Homebrew update.
- `canPerformCleanup` is computed from the selected destination, not from view-local state.

## View Composition

- `SidebarView` renders the high-level navigation groups.
- `DetailView` selects the current content view based on `selectedDestination`.
- Homebrew screens reuse shared store state so search results, selected packages, and command history persist while switching tabs.
- Applications screen state persists selected app, related-data review items, and Trash results while switching tabs.
- `HomebrewErrorBanner` is presented as an overlay from `RootView`, keeping error handling consistent across Homebrew subviews.
