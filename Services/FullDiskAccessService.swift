import AppKit
import Foundation

public enum FullDiskAccessStatus: Equatable, Sendable {
    case granted
    case denied
    case undetermined

    public var requiresUserAction: Bool {
        self != .granted
    }
}

public struct FullDiskAccessService {
    public static let privacySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!

    private let protectedLocations: () -> [URL]
    private let urlExists: (URL) -> Bool
    private let canReadURL: (URL) -> Bool
    private let openURL: (URL) -> Bool

    public init(
        protectedLocations: @escaping () -> [URL] = FullDiskAccessService.defaultProtectedLocations,
        urlExists: @escaping (URL) -> Bool = FullDiskAccessService.defaultURLExists,
        canReadURL: @escaping (URL) -> Bool = FullDiskAccessService.defaultCanReadURL,
        openURL: @escaping (URL) -> Bool = { NSWorkspace.shared.open($0) }
    ) {
        self.protectedLocations = protectedLocations
        self.urlExists = urlExists
        self.canReadURL = canReadURL
        self.openURL = openURL
    }

    public func status() -> FullDiskAccessStatus {
        var foundProtectedLocation = false

        for url in protectedLocations() where urlExists(url) {
            foundProtectedLocation = true

            if canReadURL(url) {
                return .granted
            }
        }

        return foundProtectedLocation ? .denied : .undetermined
    }

    @discardableResult
    public func openPrivacySettings() -> Bool {
        openURL(Self.privacySettingsURL)
    }

    public static func defaultProtectedLocations() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser

        return [
            home.appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db"),
            home.appendingPathComponent("Library/Messages/chat.db"),
            home.appendingPathComponent("Library/Safari/History.db"),
            home.appendingPathComponent("Library/Mail", isDirectory: true)
        ]
    }

    public static func defaultURLExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public static func defaultCanReadURL(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false

        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }

        if isDirectory.boolValue {
            return (try? FileManager.default.contentsOfDirectory(atPath: url.path)) != nil
        }

        do {
            let handle = try FileHandle(forReadingFrom: url)
            try? handle.close()
            return true
        } catch {
            return false
        }
    }
}
