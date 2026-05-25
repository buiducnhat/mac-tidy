import AppKit
import Foundation

@MainActor
enum CaskAppIconResolver {
    private static var appIndex: [String: URL]?
    private static var iconCache: [BrewPackage.ID: NSImage] = [:]

    static func icon(for package: BrewPackage) -> NSImage? {
        guard package.kind == .cask else { return nil }

        if let cachedIcon = iconCache[package.id] {
            return cachedIcon
        }

        guard let appURL = appURL(for: package.name) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        iconCache[package.id] = icon
        return icon
    }

    private static func appURL(for caskName: String) -> URL? {
        if let caskroomAppURL = caskroomAppURL(for: caskName) {
            return caskroomAppURL
        }

        let index = loadAppIndex()
        let lookupKeys = [
            caskName,
            caskName.replacingOccurrences(of: "-", with: " "),
            caskName.replacingOccurrences(of: "_", with: " ")
        ].map(normalizedName)

        return lookupKeys.compactMap { index[$0] }.first
    }

    private static func caskroomAppURL(for caskName: String) -> URL? {
        let caskroomDirectories = [
            URL(fileURLWithPath: "/opt/homebrew/Caskroom", isDirectory: true),
            URL(fileURLWithPath: "/usr/local/Caskroom", isDirectory: true)
        ]

        for directory in caskroomDirectories {
            let caskURL = directory.appendingPathComponent(caskName, isDirectory: true)
            guard let versionURLs = try? FileManager.default.contentsOfDirectory(
                at: caskURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for versionURL in versionURLs {
                guard let appURL = firstApp(in: versionURL) else { continue }
                return appURL
            }
        }

        return nil
    }

    private static func firstApp(in directory: URL) -> URL? {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isApplicationKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        return urls.first { $0.pathExtension == "app" }
    }

    private static func loadAppIndex() -> [String: URL] {
        if let appIndex {
            return appIndex
        }

        let directories = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true)
        ]

        var index: [String: URL] = [:]
        for directory in directories {
            guard let appURLs = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for appURL in appURLs where appURL.pathExtension == "app" {
                let name = appURL.deletingPathExtension().lastPathComponent
                index[normalizedName(name), default: appURL] = appURL
            }
        }

        appIndex = index
        return index
    }

    private static func normalizedName(_ name: String) -> String {
        name
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}
