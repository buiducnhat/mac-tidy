import Foundation

public enum ScanRootRules {
    public static func defaultRoots(fileManager: FileManager = .default) -> [ScanRoot] {
        let home = fileManager.homeDirectoryForCurrentUser
        let candidates: [(String, URL)] = [
            ("Home", home),
            ("Downloads", home.appendingPathComponent("Downloads", isDirectory: true)),
            ("Desktop", home.appendingPathComponent("Desktop", isDirectory: true)),
            ("Documents", home.appendingPathComponent("Documents", isDirectory: true)),
            ("Library Caches", home.appendingPathComponent("Library/Caches", isDirectory: true))
        ]

        return candidates.compactMap { title, url in
            guard isAllowedScanRoot(url, fileManager: fileManager) else { return nil }
            return ScanRoot(title: title, url: url)
        }
    }

    public static func isAllowedScanRoot(_ url: URL, fileManager: FileManager = .default) -> Bool {
        let standardizedURL = url.standardizedFileURL
        guard !ProtectedPathRules.isProtected(standardizedURL) else { return false }
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }

        return fileManager.isReadableFile(atPath: standardizedURL.path)
    }
}
