import Foundation

public enum CleanRules {
    public static func match(url: URL, root: URL, fileManager: FileManager = .default) -> ScanItem? {
        let standardizedURL = url.standardizedFileURL
        let path = standardizedURL.path
        let home = fileManager.homeDirectoryForCurrentUser.standardizedFileURL.path
        let cacheRoot = home + "/Library/Caches"

        guard path.hasPrefix(cacheRoot + "/") else { return nil }
        guard let values = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey]) else { return nil }

        return ScanItem(
            url: standardizedURL,
            size: 0,
            lastModified: values.contentModificationDate,
            category: .cache,
            risk: .low,
            cleanupPolicy: .trashAllowed
        )
    }
}
