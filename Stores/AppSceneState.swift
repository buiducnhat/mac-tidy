import MacTidyCore
import Observation

@MainActor
@Observable
final class AppSceneState {
    var selectedDestination: SidebarDestination = .dashboard
    var scanStore = ScanStore()
    var cleanStore = CleanupStore(module: .clean)
    var purgeStore = CleanupStore(module: .purge)
    var installersStore = CleanupStore(module: .installers)
    var brewStore = BrewStore(client: BrewClient())

    var canPerformCleanup: Bool {
        switch selectedDestination {
        case .clean:
            !cleanStore.selectedItems.isEmpty
        case .purge:
            !purgeStore.selectedItems.isEmpty
        case .installers:
            !installersStore.selectedItems.isEmpty
        case .dashboard, .analyze, .homebrew, .homebrewDashboard, .homebrewInstalled, .homebrewOutdated, .homebrewSearch, .homebrewTaps, .homebrewUtilities:
            false
        }
    }

    func performPrimaryScan() {
        switch selectedDestination {
        case .analyze, .dashboard:
            scanStore.scan()
        case .clean:
            cleanStore.scan()
        case .purge:
            purgeStore.scan()
        case .installers:
            installersStore.scan()
        case .homebrew, .homebrewDashboard, .homebrewInstalled, .homebrewOutdated, .homebrewSearch, .homebrewTaps:
            Task { await brewStore.refreshAll() }
        case .homebrewUtilities:
            Task { await brewStore.runUtility(.update) }
        }
    }

    func performCleanup() {
        switch selectedDestination {
        case .clean:
            cleanStore.cleanSelected()
        case .purge:
            purgeStore.cleanSelected()
        case .installers:
            installersStore.cleanSelected()
        case .dashboard, .analyze, .homebrew, .homebrewDashboard, .homebrewInstalled, .homebrewOutdated, .homebrewSearch, .homebrewTaps, .homebrewUtilities:
            break
        }
    }

    func performHomebrewSearch() {
        selectedDestination = .homebrewSearch
        Task { await brewStore.performSearch() }
    }

    func runHomebrewUpdate() {
        Task { await brewStore.runUtility(.update) }
    }

    func navigateToHomebrew(_ destination: SidebarDestination, packageFilter: BrewPackageFilter? = nil) {
        switch destination {
        case .homebrewInstalled:
            brewStore.installedPackageFilter = packageFilter ?? .all
        case .homebrewOutdated:
            brewStore.outdatedPackageFilter = packageFilter ?? .all
        default:
            break
        }

        brewStore.selectedPackageID = nil
        selectedDestination = destination
    }
}
