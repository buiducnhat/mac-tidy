import Foundation
import MacTidyCore
import Observation

@MainActor
@Observable
final class ScanStore {
    enum State: Equatable {
        case idle
        case scanning
        case complete
        case cancelled
        case failed(String)
    }

    var roots: [ScanRoot]
    var selectedRootIDs: Set<ScanRoot.ID>
    var items: [ScanItem] = []
    var diagnostics: [ScanDiagnostic] = []
    var summary: ScanSummary?
    var state: State = .idle

    private let scanService: ScanService
    private var scanTask: Task<Void, Never>?

    init(roots: [ScanRoot] = ScanRootRules.defaultRoots(), scanService: ScanService = ScanService()) {
        self.roots = roots
        self.selectedRootIDs = Set(roots.filter(\.isDefault).map(\.id))
        self.scanService = scanService
    }

    var selectedRoots: [ScanRoot] {
        roots.filter { selectedRootIDs.contains($0.id) }
    }

    var isScanning: Bool {
        if case .scanning = state { return true }
        return false
    }

    func toggleRoot(_ root: ScanRoot, isSelected: Bool) {
        if isSelected {
            selectedRootIDs.insert(root.id)
        } else {
            selectedRootIDs.remove(root.id)
        }
    }

    func scan() {
        guard !selectedRoots.isEmpty else {
            state = .failed("Select at least one scan root.")
            return
        }

        scanTask?.cancel()
        state = .scanning
        items = []
        diagnostics = []
        summary = ScanSummary.empty

        let rootsToScan = selectedRoots.filter { !Self.isExcluded($0.url) }
        scanTask = Task {
            do {
                let result = try await scanService.scan(roots: rootsToScan)
                guard !Task.isCancelled else {
                    markCancelled(startedAt: result.summary.startedAt)
                    return
                }

                items = result.items
                diagnostics = result.diagnostics
                summary = result.summary
                state = .complete
            } catch is CancellationError {
                markCancelled(startedAt: summary?.startedAt ?? Date())
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func cancel() {
        scanTask?.cancel()
        markCancelled(startedAt: summary?.startedAt ?? Date())
    }

    private func markCancelled(startedAt: Date) {
        summary = ScanSummary(
            scannedRoots: selectedRoots.count,
            itemCount: items.count,
            totalBytes: items.reduce(0) { $0 + $1.size },
            diagnosticsCount: diagnostics.count,
            startedAt: startedAt,
            finishedAt: Date(),
            wasCancelled: true
        )
        state = .cancelled
    }

    static func isExcluded(_ url: URL) -> Bool {
        let raw = UserDefaults.standard.string(forKey: "excludedPaths") ?? ""
        let path = url.standardizedFileURL.path
        return raw
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .contains { excluded in
                path == excluded || path.hasPrefix(excluded + "/")
            }
    }
}
