import Foundation

public enum InstallerRules {
    private static let installerExtensions: Set<String> = ["dmg", "pkg", "mpkg", "iso", "xip"]

    public static func match(url: URL) -> ScanItem? {
        let standardizedURL = url.standardizedFileURL
        let fileExtension = standardizedURL.pathExtension.lowercased()
        let name = standardizedURL.lastPathComponent.lowercased()

        guard installerExtensions.contains(fileExtension) || (fileExtension == "zip" && name.contains("install")) else {
            return nil
        }

        guard let values = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey]), values.isDirectory != true else {
            return nil
        }

        return ScanItem(
            url: standardizedURL,
            size: 0,
            lastModified: values.contentModificationDate,
            category: .installer,
            risk: fileExtension == "zip" ? .review : .low,
            cleanupPolicy: fileExtension == "zip" ? .reviewRequired : .trashAllowed
        )
    }
}
