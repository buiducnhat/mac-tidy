import Foundation

public struct CleanupService {
    public var fileManager: FileManager
    private var trash: (URL) throws -> URL?

    public init(fileManager: FileManager = .default, trash: @escaping (URL) throws -> URL? = CleanupService.defaultTrash) {
        self.fileManager = fileManager
        self.trash = trash
    }

    public func moveToTrash(urls: [URL]) -> [CleanupResult] {
        let results = SelectionDeduper.collapse(urls).map { url in
            let standardizedURL = url.standardizedFileURL

            guard !ProtectedPathRules.isProtected(standardizedURL) else {
                AppLog.cleanup.info("Cleanup refused protected item")
                return CleanupResult(url: standardizedURL, status: .refused, message: "Protected paths cannot be cleaned.")
            }

            guard fileManager.fileExists(atPath: standardizedURL.path) else {
                AppLog.cleanup.info("Cleanup refused missing item")
                return CleanupResult(url: standardizedURL, status: .refused, message: "Item no longer exists.")
            }

            if (try? standardizedURL.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true {
                AppLog.cleanup.info("Cleanup refused symlink")
                return CleanupResult(url: standardizedURL, status: .refused, message: "Symlinks are not cleaned by this MVP.")
            }

            do {
                _ = try trash(standardizedURL)
                AppLog.cleanup.info("Cleanup moved item to Trash")
                return CleanupResult(url: standardizedURL, status: .movedToTrash, message: "Moved to Trash.")
            } catch {
                AppLog.cleanup.error("Cleanup failed")
                return CleanupResult(url: standardizedURL, status: .failed, message: error.localizedDescription)
            }
        }

        AppLog.cleanup.info("Cleanup finished: total=\(results.count)")
        return results
    }

    public static func defaultTrash(_ url: URL) throws -> URL? {
        var resultingURL: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
        return resultingURL as URL?
    }
}
