import Foundation
import MacTidyCore
import Observation

@MainActor
@Observable
final class ApplicationsStore {
    enum State: Equatable {
        case idle
        case scanning
        case loadingReview
        case complete
        case uninstalling
        case uninstalled
        case failed(String)
    }

    var applications: [InstalledApplication] = []
    var selectedApplicationID: InstalledApplication.ID?
    var uninstallItems: [ApplicationUninstallItem] = []
    var selectedUninstallItemIDs: Set<ApplicationUninstallItem.ID> = []
    var results: [CleanupResult] = []
    var state: State = .idle
    var errorMessage: String?

    private let applicationScanner: InstalledApplicationScanner
    private let dataScanner: ApplicationDataScanner
    private let cleanupService: CleanupService
    private let finderService: FinderService
    private var scanTask: Task<Void, Never>?
    private var reviewTask: Task<Void, Never>?
    private var uninstallItemsByApplicationID: [InstalledApplication.ID: [ApplicationUninstallItem]] = [:]

    init(
        applicationScanner: InstalledApplicationScanner = InstalledApplicationScanner(),
        dataScanner: ApplicationDataScanner = ApplicationDataScanner(),
        cleanupService: CleanupService = CleanupService(),
        finderService: FinderService = FinderService()
    ) {
        self.applicationScanner = applicationScanner
        self.dataScanner = dataScanner
        self.cleanupService = cleanupService
        self.finderService = finderService
    }

    var isBusy: Bool {
        state == .scanning || state == .loadingReview || state == .uninstalling
    }

    var selectedApplication: InstalledApplication? {
        applications.first { $0.id == selectedApplicationID }
    }

    var selectedUninstallItems: [ApplicationUninstallItem] {
        uninstallItems.filter { selectedUninstallItemIDs.contains($0.id) }
    }

    var selectedBytes: Int64 {
        selectedUninstallItems.reduce(0) { $0 + $1.size }
    }

    func scanApplications() {
        scanTask?.cancel()
        reviewTask?.cancel()
        applications = []
        selectedApplicationID = nil
        uninstallItems = []
        uninstallItemsByApplicationID = [:]
        selectedUninstallItemIDs = []
        results = []
        errorMessage = nil
        state = .scanning

        scanTask = Task {
            do {
                let found = try await applicationScanner.scan()
                guard !Task.isCancelled else { return }
                applications = found
                selectedApplicationID = found.first?.id
                state = .complete
                refreshUninstallItems()
            } catch is CancellationError {
                state = .idle
            } catch {
                errorMessage = error.localizedDescription
                state = .failed(error.localizedDescription)
            }
        }
    }

    func selectApplication(_ application: InstalledApplication?) {
        selectedApplicationID = application?.id
        refreshUninstallItems()
    }

    func refreshUninstallItems() {
        reviewTask?.cancel()
        uninstallItems = []
        selectedUninstallItemIDs = []
        guard let application = selectedApplication else {
            state = .complete
            return
        }
        if uninstallItemsByApplicationID[application.id] != nil {
            loadCachedUninstallItems()
            return
        }

        errorMessage = nil
        let bundleItem = appBundleItem(for: application)
        uninstallItems = [bundleItem]
        selectedUninstallItemIDs = bundleItem.isSelectedByDefault ? [bundleItem.id] : []
        state = .loadingReview
        reviewTask = Task {
            do {
                let items = try await dataScanner.scan(for: application)
                guard !Task.isCancelled, selectedApplicationID == application.id else { return }
                uninstallItemsByApplicationID[application.id] = items
                uninstallItems = items
                selectedUninstallItemIDs = Set(items.filter(\.isSelectedByDefault).map(\.id))
                state = .complete
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
                state = .failed(error.localizedDescription)
            }
        }
    }

    func toggleUninstallItem(_ item: ApplicationUninstallItem, isSelected: Bool) {
        if isSelected {
            selectedUninstallItemIDs.insert(item.id)
        } else {
            selectedUninstallItemIDs.remove(item.id)
        }
    }

    func uninstallSelectedItems() {
        let items = selectedUninstallItems
        guard !items.isEmpty else { return }

        state = .uninstalling
        results = cleanupService.moveToTrash(urls: items.map(\.url))
        let movedPaths = Set(results.filter { $0.status == .movedToTrash }.map { $0.url.standardizedFileURL.path })
        applications.removeAll { movedPaths.contains($0.url.standardizedFileURL.path) }
        uninstallItems.removeAll { movedPaths.contains($0.url.standardizedFileURL.path) }
        uninstallItemsByApplicationID = uninstallItemsByApplicationID.mapValues { items in
            items.filter { !movedPaths.contains($0.url.standardizedFileURL.path) }
        }
        selectedUninstallItemIDs.removeAll()

        if let selectedApplicationID, !applications.contains(where: { $0.id == selectedApplicationID }) {
            self.selectedApplicationID = applications.first?.id
            refreshUninstallItems()
        } else {
            state = .uninstalled
        }
    }

    func reveal(_ item: ApplicationUninstallItem) {
        finderService.reveal(item.url)
    }

    func reveal(_ application: InstalledApplication) {
        finderService.reveal(application.url)
    }

    private func loadCachedUninstallItems() {
        guard let selectedApplication else {
            uninstallItems = []
            selectedUninstallItemIDs = []
            state = .complete
            return
        }

        let items = uninstallItemsByApplicationID[selectedApplication.id] ?? []
        uninstallItems = items
        selectedUninstallItemIDs = Set(items.filter(\.isSelectedByDefault).map(\.id))
        state = .complete
    }

    private func appBundleItem(for application: InstalledApplication) -> ApplicationUninstallItem {
        ApplicationUninstallItem(
            url: application.url,
            name: application.displayName,
            size: application.size,
            kind: .appBundle,
            risk: application.isUninstallable ? .review : .blocked,
            cleanupPolicy: application.isUninstallable ? .trashAllowed : .blocked,
            isSelectedByDefault: application.isUninstallable
        )
    }
}
