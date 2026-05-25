import MacTidyCore
import SwiftUI

struct DetailView: View {
    @Bindable var appState: AppSceneState

    var body: some View {
        Group {
            switch appState.selectedDestination {
            case .dashboard:
                DashboardView(scanStore: appState.scanStore)
            case .analyze:
                AnalyzeView(scanStore: appState.scanStore)
            case .clean:
                CleanView(store: appState.cleanStore)
            case .purge:
                PurgeView(store: appState.purgeStore)
            case .installers:
                InstallersView(store: appState.installersStore)
            case .homebrew, .homebrewDashboard:
                HomebrewDashboardView(store: appState.brewStore) { destination, packageFilter in
                    appState.navigateToHomebrew(destination, packageFilter: packageFilter)
                }
                .task {
                    await appState.brewStore.loadInitialData()
                }
            case .homebrewInstalled:
                HomebrewPackagesView(
                    title: "Installed Packages",
                    packages: appState.brewStore.installedPackages,
                    packageFilter: $appState.brewStore.installedPackageFilter,
                    store: appState.brewStore,
                    emptyMessage: "No installed formulae or casks were found."
                )
                .task {
                    await appState.brewStore.loadInitialData()
                }
            case .homebrewOutdated:
                HomebrewPackagesView(
                    title: "Outdated Packages",
                    packages: appState.brewStore.outdatedPackages,
                    packageFilter: $appState.brewStore.outdatedPackageFilter,
                    store: appState.brewStore,
                    emptyMessage: "Everything is current."
                )
                .task {
                    await appState.brewStore.loadInitialData()
                }
            case .homebrewSearch:
                HomebrewSearchView(store: appState.brewStore)
            case .homebrewTaps:
                HomebrewTapsView(store: appState.brewStore)
                .task {
                    await appState.brewStore.loadInitialData()
                }
            case .homebrewUtilities:
                HomebrewUtilitiesView(store: appState.brewStore)
            }
        }
        .navigationTitle(appState.selectedDestination.title)
    }
}
