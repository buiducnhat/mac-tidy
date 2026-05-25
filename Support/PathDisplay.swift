import Foundation

public enum PathDisplay {
    public static func abbreviated(_ url: URL, fileManager: FileManager = .default) -> String {
        let path = url.standardizedFileURL.path
        let homePath = fileManager.homeDirectoryForCurrentUser.standardizedFileURL.path

        if path == homePath {
            return "~"
        }

        if path.hasPrefix(homePath + "/") {
            return "~" + path.dropFirst(homePath.count)
        }

        return path
    }
}
