import Foundation
import MacTidyCore
import Observation

@MainActor
@Observable
final class CleanupStore {
    enum State: Equatable {
        case idle
        case scanning
        case complete
        case cleaning
        case cleaned
        case failed(String)
    }

    let module: CleanupModule
    var roots: [ScanRoot]
    var candidates: [ScanItem] = []
    var selectedIDs: Set<ScanItem.ID> = []
    var results: [CleanupResult] = []
    var state: State = .idle

    private let scanner: CleanupCandidateScanner
    private let cleanupService: CleanupService
    private let finderService: FinderService
    private var scanTask: Task<Void, Never>?

    init(
        module: CleanupModule,
        roots: [ScanRoot] = ScanRootRules.defaultRoots(),
        scanner: CleanupCandidateScanner = CleanupCandidateScanner(),
        cleanupService: CleanupService = CleanupService(),
        finderService: FinderService = FinderService()
    ) {
        self.module = module
        self.roots = roots
        self.scanner = scanner
        self.cleanupService = cleanupService
        self.finderService = finderService
    }

    var isBusy: Bool {
        state == .scanning || state == .cleaning
    }

    var selectedItems: [ScanItem] {
        candidates.filter { selectedIDs.contains($0.id) }
    }

    var selectedBytes: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    func scan() {
        scanTask?.cancel()
        candidates = []
        selectedIDs = []
        results = []
        state = .scanning

        let rootsToScan = roots.filter { !ScanStore.isExcluded($0.url) }
        let module = module
        scanTask = Task {
            do {
                let found = try await scanner.scan(module: module, roots: rootsToScan)
                guard !Task.isCancelled else { return }
                candidates = found
                if UserDefaults.standard.object(forKey: "defaultSelectLowRisk") as? Bool ?? true {
                    selectedIDs = Set(found.filter { $0.cleanupPolicy == .trashAllowed && $0.risk == .low }.map(\.id))
                }
                state = .complete
            } catch is CancellationError {
                state = .idle
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func toggle(_ item: ScanItem, isSelected: Bool) {
        if isSelected {
            selectedIDs.insert(item.id)
        } else {
            selectedIDs.remove(item.id)
        }
    }

    func reveal(_ item: ScanItem) {
        finderService.reveal(item.url)
    }

    func cleanSelected() {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        state = .cleaning
        results = cleanupService.moveToTrash(urls: urls)
        let moved = Set(results.filter { $0.status == .movedToTrash }.map { $0.url.standardizedFileURL.path })
        candidates.removeAll { moved.contains($0.url.standardizedFileURL.path) }
        selectedIDs.removeAll()
        state = .cleaned
    }
}
