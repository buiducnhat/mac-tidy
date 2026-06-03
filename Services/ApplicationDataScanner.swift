import Foundation

public struct ApplicationDataScanner {
    public var libraryRoots: [URL]
    public var fileManager: FileManager

    private let appNameSuffixes = [
        ".plist",
        ".savedState",
        ".binarycookies"
    ]

    public init(libraryRoots: [URL]? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let libraryRoots {
            self.libraryRoots = libraryRoots.map(\.standardizedFileURL)
        } else {
            let library = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true)
            self.libraryRoots = [
                "Application Support",
                "Caches",
                "Preferences",
                "Containers",
                "Group Containers",
                "Logs",
                "Saved Application State",
                "HTTPStorages",
                "WebKit"
            ].map { library.appendingPathComponent($0, isDirectory: true).standardizedFileURL }
        }
    }

    public func scan(for application: InstalledApplication) async throws -> [ApplicationUninstallItem] {
        try await Task.detached(priority: .userInitiated) {
            var items = [appBundleItem(for: application)]

            for root in libraryRoots {
                try Task.checkCancellation()
                guard fileManager.fileExists(atPath: root.path) else { continue }
                try scan(root: root, application: application, items: &items)
            }

            return sortedReviewItems(items)
        }.value
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

    private func scan(root: URL, application: InstalledApplication, items: inout [ApplicationUninstallItem]) throws {
        let rootURL = root.standardizedFileURL
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return }

        for case let url as URL in enumerator {
            try Task.checkCancellation()
            let standardizedURL = url.standardizedFileURL
            guard standardizedURL != rootURL, ProtectedPathRules.isContained(standardizedURL, in: rootURL) else {
                enumerator.skipDescendants()
                continue
            }
            guard !ProtectedPathRules.isProtected(standardizedURL) else {
                enumerator.skipDescendants()
                continue
            }
            guard let values = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]) else { continue }
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }

            guard matches(standardizedURL, application: application) else { continue }
            items.append(
                ApplicationUninstallItem(
                    url: standardizedURL,
                    size: size(of: standardizedURL),
                    kind: .relatedData,
                    risk: .review,
                    cleanupPolicy: .reviewRequired,
                    isSelectedByDefault: false
                )
            )
            if values.isDirectory == true {
                enumerator.skipDescendants()
            }
        }
    }

    private func matches(_ url: URL, application: InstalledApplication) -> Bool {
        let component = url.lastPathComponent
        if let bundleIdentifier = application.bundleIdentifier, matchesBundleIdentifier(component, bundleIdentifier: bundleIdentifier) {
            return true
        }
        return matchesAppName(component, displayName: application.displayName)
    }

    private func matchesBundleIdentifier(_ component: String, bundleIdentifier: String) -> Bool {
        let lowercasedComponent = component.lowercased()
        let lowercasedIdentifier = bundleIdentifier.lowercased()
        return lowercasedComponent == lowercasedIdentifier
            || lowercasedComponent == "\(lowercasedIdentifier).plist"
            || lowercasedComponent == "\(lowercasedIdentifier).savedstate"
    }

    private func matchesAppName(_ component: String, displayName: String) -> Bool {
        let lowercasedComponent = component.lowercased()
        let lowercasedDisplayName = displayName.lowercased()
        if lowercasedComponent == lowercasedDisplayName { return true }
        return appNameSuffixes.contains { suffix in
            lowercasedComponent == "\(lowercasedDisplayName)\(suffix.lowercased())"
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

    private func sortedReviewItems(_ items: [ApplicationUninstallItem]) -> [ApplicationUninstallItem] {
        let appItems = items.filter { $0.kind == .appBundle }
        let relatedItems = items.filter { $0.kind == .relatedData }.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        return appItems + relatedItems
    }
}
