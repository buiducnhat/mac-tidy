import Foundation

public struct ScanService {
    public var fileManager: FileManager
    public var maxItemsPerRoot: Int
    public var diagnostics: PermissionDiagnosticsService

    public init(fileManager: FileManager = .default, maxItemsPerRoot: Int = 500, diagnostics: PermissionDiagnosticsService = PermissionDiagnosticsService()) {
        self.fileManager = fileManager
        self.maxItemsPerRoot = maxItemsPerRoot
        self.diagnostics = diagnostics
    }

    public func scan(roots: [ScanRoot]) async throws -> ScanServiceResult {
        try await Task.detached(priority: .userInitiated) {
            var items: [ScanItem] = []
            var scanDiagnostics: [ScanDiagnostic] = []
            let startedAt = Date()

            for root in roots {
                try Task.checkCancellation()

                guard ScanRootRules.isAllowedScanRoot(root.url, fileManager: fileManager) else {
                    scanDiagnostics.append(diagnostics.diagnostic(for: root.url, message: "This scan root is not allowed or is not readable."))
                    continue
                }

                let result = try scanRoot(root)
                items.append(contentsOf: result.items)
                scanDiagnostics.append(contentsOf: result.diagnostics)
            }

            items.sort { lhs, rhs in
                if lhs.size == rhs.size {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.size > rhs.size
            }

            let summary = ScanSummary(
                scannedRoots: roots.count,
                itemCount: items.count,
                totalBytes: items.reduce(0) { $0 + $1.size },
                diagnosticsCount: scanDiagnostics.count + items.reduce(0) { $0 + $1.diagnostics.count },
                startedAt: startedAt,
                finishedAt: Date(),
                wasCancelled: false
            )

            AppLog.scan.info("Scan finished: roots=\(summary.scannedRoots), items=\(summary.itemCount), diagnostics=\(summary.diagnosticsCount)")

            return ScanServiceResult(items: items, diagnostics: scanDiagnostics, summary: summary)
        }.value
    }

    private func scanRoot(_ root: ScanRoot) throws -> ScanRootResult {
        let rootURL = root.url.standardizedFileURL
        guard let childURLs = try? fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return ScanRootResult(items: [], diagnostics: [diagnostics.diagnostic(for: rootURL)])
        }

        var items: [ScanItem] = []
        var scanDiagnostics: [ScanDiagnostic] = []

        for childURL in childURLs.prefix(maxItemsPerRoot) {
            try Task.checkCancellation()

            let standardizedURL = childURL.standardizedFileURL
            guard ProtectedPathRules.isContained(standardizedURL, in: rootURL) else { continue }

            let values = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey, .fileSizeKey])
            if values?.isSymbolicLink == true {
                continue
            }

            let sizeResult = size(of: standardizedURL, root: rootURL)
            scanDiagnostics.append(contentsOf: sizeResult.diagnostics)
            items.append(
                ScanItem(
                    url: standardizedURL,
                    size: sizeResult.bytes,
                    lastModified: values?.contentModificationDate,
                    category: values?.isDirectory == true ? .folder : .file,
                    risk: .review,
                    cleanupPolicy: .scanOnly,
                    diagnostics: sizeResult.itemDiagnostics
                )
            )
        }

        if childURLs.count > maxItemsPerRoot {
            scanDiagnostics.append(
                ScanDiagnostic(
                    path: rootURL.path,
                    message: "Results were capped at \(maxItemsPerRoot) items for this root."
                )
            )
        }

        return ScanRootResult(items: items, diagnostics: scanDiagnostics)
    }

    private func size(of url: URL, root: URL) -> SizeResult {
        var bytes: Int64 = 0
        var rootDiagnostics: [ScanDiagnostic] = []
        var itemDiagnostics: [ScanDiagnostic] = []

        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]) else {
            let diagnostic = diagnostics.diagnostic(for: url)
            return SizeResult(bytes: 0, diagnostics: [diagnostic], itemDiagnostics: [diagnostic])
        }

        if values.isSymbolicLink == true {
            return SizeResult(bytes: 0, diagnostics: [], itemDiagnostics: [])
        }

        if values.isDirectory != true {
            return SizeResult(bytes: Int64(values.fileSize ?? 0), diagnostics: [], itemDiagnostics: [])
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: { failedURL, error in
                let diagnostic = diagnostics.diagnostic(for: failedURL, message: error.localizedDescription)
                rootDiagnostics.append(diagnostic)
                itemDiagnostics.append(diagnostic)
                return true
            }
        ) else {
            let diagnostic = diagnostics.diagnostic(for: url)
            return SizeResult(bytes: 0, diagnostics: [diagnostic], itemDiagnostics: [diagnostic])
        }

        for case let fileURL as URL in enumerator {
            if Task.isCancelled { break }
            let standardizedURL = fileURL.standardizedFileURL
            guard ProtectedPathRules.isContained(standardizedURL, in: root) else {
                enumerator.skipDescendants()
                continue
            }

            guard let fileValues = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]) else {
                let diagnostic = diagnostics.diagnostic(for: standardizedURL)
                rootDiagnostics.append(diagnostic)
                itemDiagnostics.append(diagnostic)
                continue
            }

            if fileValues.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }

            if fileValues.isDirectory != true {
                bytes += Int64(fileValues.fileSize ?? 0)
            }
        }

        return SizeResult(bytes: bytes, diagnostics: rootDiagnostics, itemDiagnostics: itemDiagnostics)
    }
}

public struct ScanServiceResult {
    public let items: [ScanItem]
    public let diagnostics: [ScanDiagnostic]
    public let summary: ScanSummary

    public init(items: [ScanItem], diagnostics: [ScanDiagnostic], summary: ScanSummary) {
        self.items = items
        self.diagnostics = diagnostics
        self.summary = summary
    }
}

private struct ScanRootResult {
    let items: [ScanItem]
    let diagnostics: [ScanDiagnostic]
}

private struct SizeResult {
    let bytes: Int64
    let diagnostics: [ScanDiagnostic]
    let itemDiagnostics: [ScanDiagnostic]
}
