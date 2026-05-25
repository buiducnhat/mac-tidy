import Foundation

public enum ProtectedPathRules {
    private static let protectedPrefixes = [
        "/System",
        "/bin",
        "/sbin",
        "/usr/bin",
        "/usr/sbin",
        "/etc",
        "/var/db"
    ]

    public static func isProtected(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return protectedPrefixes.contains { prefix in
            path == prefix || path.hasPrefix(prefix + "/")
        }
    }

    public static func isContained(_ child: URL, in root: URL) -> Bool {
        let childPath = child.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        return childPath == rootPath || childPath.hasPrefix(rootPath + "/")
    }
}
