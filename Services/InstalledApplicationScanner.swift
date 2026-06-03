import Foundation

public struct InstalledApplicationScanner {
    public var roots: [URL]
    public var inventoryOnlyRoots: [URL]
    public var fileManager: FileManager

    public init(
        roots: [URL]? = nil,
        inventoryOnlyRoots: [URL] = [URL(fileURLWithPath: "/System/Applications", isDirectory: true)],
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.inventoryOnlyRoots = inventoryOnlyRoots.map(\.standardizedFileURL)

        if let roots {
            self.roots = roots.map(\.standardizedFileURL)
        } else {
            var defaultRoots = [
                URL(fileURLWithPath: "/Applications", isDirectory: true),
                URL(fileURLWithPath: "/System/Applications", isDirectory: true)
            ]
            let userApplications = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
            if fileManager.fileExists(atPath: userApplications.path) {
                defaultRoots.append(userApplications)
            }
            self.roots = defaultRoots.map(\.standardizedFileURL)
        }
    }

    public func scan() async throws -> [InstalledApplication] {
        try await Task.detached(priority: .userInitiated) {
            var applications: [InstalledApplication] = []

            for root in roots {
                try Task.checkCancellation()
                guard fileManager.fileExists(atPath: root.path) else { continue }
                try scan(root: root, applications: &applications)
            }

            return applications.sorted {
                let nameComparison = $0.displayName.localizedCaseInsensitiveCompare($1.displayName)
                if nameComparison == .orderedSame {
                    return $0.url.path.localizedCaseInsensitiveCompare($1.url.path) == .orderedAscending
                }
                return nameComparison == .orderedAscending
            }
        }.value
    }

    private func scan(root: URL, applications: inout [InstalledApplication]) throws {
        let rootURL = root.standardizedFileURL
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return }

        for case let url as URL in enumerator {
            try Task.checkCancellation()
            let standardizedURL = url.standardizedFileURL
            guard ProtectedPathRules.isContained(standardizedURL, in: rootURL) else {
                enumerator.skipDescendants()
                continue
            }

            guard let values = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey]) else {
                continue
            }
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }

            guard values.isDirectory == true, standardizedURL.pathExtension == "app" else { continue }
            applications.append(application(from: standardizedURL, root: rootURL, lastModified: values.contentModificationDate))
            enumerator.skipDescendants()
        }
    }

    private func application(from url: URL, root: URL, lastModified: Date?) -> InstalledApplication {
        let metadata = metadata(for: url)
        let isInventoryOnly = inventoryOnlyRoots.contains { ProtectedPathRules.isContained(url, in: $0) }
        let isUninstallable = !isInventoryOnly && !ProtectedPathRules.isProtected(url)

        return InstalledApplication(
            url: url,
            displayName: metadata.displayName,
            bundleIdentifier: metadata.bundleIdentifier,
            version: metadata.version,
            size: size(of: url),
            lastModified: lastModified,
            sourceRoot: root,
            isUninstallable: isUninstallable
        )
    }

    private func metadata(for url: URL) -> (displayName: String, bundleIdentifier: String?, version: String?) {
        let infoURL = url.appendingPathComponent("Contents/Info.plist")
        let plist = NSDictionary(contentsOf: infoURL) as? [String: Any]
        let displayName = plist?["CFBundleDisplayName"] as? String
            ?? plist?["CFBundleName"] as? String
            ?? url.deletingPathExtension().lastPathComponent
        let bundleIdentifier = plist?["CFBundleIdentifier"] as? String
        let version = plist?["CFBundleShortVersionString"] as? String
            ?? plist?["CFBundleVersion"] as? String

        return (displayName, bundleIdentifier, version)
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
