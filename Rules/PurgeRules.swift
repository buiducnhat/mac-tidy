import Foundation

public enum PurgeRules {
    private static let artifactNames: Set<String> = [
        "node_modules",
        ".build",
        "DerivedData",
        "target",
        "dist",
        ".next",
        "Pods"
    ]

    public static func match(url: URL) -> ScanItem? {
        let standardizedURL = url.standardizedFileURL
        let name = standardizedURL.lastPathComponent
        let parentName = standardizedURL.deletingLastPathComponent().lastPathComponent

        let matchesArtifact = artifactNames.contains(name) || (name == "Build" && parentName == "Carthage")
        guard matchesArtifact else { return nil }
        guard let values = try? standardizedURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey]), values.isDirectory == true else {
            return nil
        }

        return ScanItem(
            url: standardizedURL,
            size: 0,
            lastModified: values.contentModificationDate,
            category: .projectArtifact,
            risk: .review,
            cleanupPolicy: .reviewRequired
        )
    }
}
