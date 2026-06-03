import Foundation

public struct InstalledApplication: Identifiable, Hashable {
    public let id: String
    public let url: URL
    public let displayName: String
    public let bundleIdentifier: String?
    public let version: String?
    public let size: Int64
    public let lastModified: Date?
    public let sourceRoot: URL
    public let isUninstallable: Bool

    public init(
        url: URL,
        displayName: String,
        bundleIdentifier: String?,
        version: String?,
        size: Int64,
        lastModified: Date?,
        sourceRoot: URL,
        isUninstallable: Bool
    ) {
        let standardizedURL = url.standardizedFileURL
        self.id = standardizedURL.path
        self.url = standardizedURL
        self.displayName = displayName
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.size = size
        self.lastModified = lastModified
        self.sourceRoot = sourceRoot.standardizedFileURL
        self.isUninstallable = isUninstallable
    }
}
