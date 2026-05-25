import Foundation

public struct CleanupCandidateScanner {
    public var fileManager: FileManager
    public var maxCandidates: Int

    public init(fileManager: FileManager = .default, maxCandidates: Int = 500) {
        self.fileManager = fileManager
        self.maxCandidates = maxCandidates
    }

    public func scan(module: CleanupModule, roots: [ScanRoot]) async throws -> [ScanItem] {
        try await Task.detached(priority: .userInitiated) {
            var candidates: [ScanItem] = []

            for root in roots {
                try Task.checkCancellation()
                guard ScanRootRules.isAllowedScanRoot(root.url, fileManager: fileManager) else { continue }
                try scan(root: root.url, module: module, candidates: &candidates)
                if candidates.count >= maxCandidates { break }
            }

            return candidates.sorted {
                if $0.size == $1.size {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.size > $1.size
            }
        }.value
    }

    private func scan(root: URL, module: CleanupModule, candidates: inout [ScanItem]) throws {
        let rootURL = root.standardizedFileURL
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return }

        for case let url as URL in enumerator {
            try Task.checkCancellation()
            if candidates.count >= maxCandidates { return }

            let standardizedURL = url.standardizedFileURL
            guard ProtectedPathRules.isContained(standardizedURL, in: rootURL), !ProtectedPathRules.isProtected(standardizedURL) else {
                enumerator.skipDescendants()
                continue
            }

            guard let values = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]) else { continue }
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }

            if var item = match(url: standardizedURL, root: rootURL, module: module) {
                item = ScanItem(
                    url: item.url,
                    size: size(of: item.url),
                    lastModified: item.lastModified,
                    category: item.category,
                    risk: item.risk,
                    cleanupPolicy: item.cleanupPolicy,
                    diagnostics: item.diagnostics
                )
                candidates.append(item)

                if values.isDirectory == true {
                    enumerator.skipDescendants()
                }
            }
        }
    }

    private func match(url: URL, root: URL, module: CleanupModule) -> ScanItem? {
        switch module {
        case .clean:
            CleanRules.match(url: url, root: root, fileManager: fileManager)
        case .purge:
            PurgeRules.match(url: url)
        case .installers:
            InstallerRules.match(url: url)
        }
    }

    private func size(of url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]) else { return 0 }
        if values.isSymbolicLink == true { return 0 }
        if values.isDirectory != true { return Int64(values.fileSize ?? 0) }

        var bytes: Int64 = 0
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            guard let fileValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]) else { continue }
            if fileValues.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }
            if fileValues.isDirectory != true {
                bytes += Int64(fileValues.fileSize ?? 0)
            }
        }

        return bytes
    }
}
