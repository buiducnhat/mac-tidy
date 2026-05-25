import Foundation

enum BrewPackageKind: String, CaseIterable, Identifiable, Sendable {
    case formula = "Formula"
    case cask = "Cask"

    var id: String { rawValue }
    var commandFlag: String {
        switch self {
        case .formula: "--formula"
        case .cask: "--cask"
        }
    }
}

enum BrewPackageFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case formulae = "Formulae"
    case casks = "Casks"

    var id: String { rawValue }

    func includes(_ package: BrewPackage) -> Bool {
        switch self {
        case .all:
            true
        case .formulae:
            package.kind == .formula
        case .casks:
            package.kind == .cask
        }
    }
}

struct BrewPackage: Identifiable, Hashable, Sendable {
    var id: String { "\(kind.rawValue):\(name)" }
    let name: String
    let kind: BrewPackageKind
    var installedVersion: String?
    var currentVersion: String?
    var description: String?
    var displayName: String?
    var installedAt: Date?
    var lastUsedAt: Date?
    var sizeBytes: Int64?

    var isOutdated: Bool {
        currentVersion != nil && currentVersion != installedVersion
    }

    var versionSummary: String {
        switch (installedVersion, currentVersion) {
        case let (.some(installed), .some(current)) where installed != current:
            "\(installed) -> \(current)"
        case let (.some(installed), _):
            installed
        case let (_, .some(current)):
            current
        default:
            "Unknown"
        }
    }

    var title: String {
        displayName?.isEmpty == false ? displayName! : name
    }

    var showsDisplayName: Bool {
        guard let displayName, !displayName.isEmpty else { return false }
        return displayName.localizedCaseInsensitiveCompare(name) != .orderedSame
    }
}

struct BrewTap: Identifiable, Hashable, Sendable {
    var id: String { name }
    let name: String
}

struct BrewCommandResult: Identifiable, Hashable, Sendable {
    let id = UUID()
    let command: String
    let exitCode: Int32
    let output: String
    let startedAt: Date
    let finishedAt: Date

    var succeeded: Bool { exitCode == 0 }
    var duration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
}

struct BrewPackageInfo: Identifiable, Hashable, Sendable {
    let id = UUID()
    let package: BrewPackage
    let headline: String
    let description: String?
    let homepage: URL?
    let status: String?
    let sections: [BrewInfoSection]
    let command: String
}

struct BrewInfoSection: Identifiable, Hashable, Sendable {
    var id: String { title }
    let title: String
    let body: String
}

enum BrewUtility: String, CaseIterable, Identifiable, Sendable {
    case update = "Update Metadata"
    case doctor = "Doctor"
    case cleanupDryRun = "Cleanup Preview"
    case cleanup = "Cleanup"
    case autoremoveDryRun = "Autoremove Preview"
    case autoremove = "Autoremove"
    case upgradeAll = "Upgrade All"
    case bundleDump = "Dump Brewfile"
    case bundleCheck = "Check Brewfile"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .update: "arrow.triangle.2.circlepath"
        case .doctor: "stethoscope"
        case .cleanupDryRun, .cleanup: "trash"
        case .autoremoveDryRun, .autoremove: "wand.and.stars"
        case .upgradeAll: "square.and.arrow.up"
        case .bundleDump: "doc.badge.arrow.up"
        case .bundleCheck: "checklist"
        }
    }

    var commandArguments: [String] {
        switch self {
        case .update: ["update"]
        case .doctor: ["doctor"]
        case .cleanupDryRun: ["cleanup", "--dry-run"]
        case .cleanup: ["cleanup"]
        case .autoremoveDryRun: ["autoremove", "--dry-run"]
        case .autoremove: ["autoremove"]
        case .upgradeAll: ["upgrade"]
        case .bundleDump: ["bundle", "dump", "--describe", "--force"]
        case .bundleCheck: ["bundle", "check", "--verbose"]
        }
    }

    var detail: String {
        switch self {
        case .update: "Fetch the newest formula and cask metadata."
        case .doctor: "Run diagnostics for common Homebrew setup issues."
        case .cleanupDryRun: "Preview old downloads, locks, and versions to remove."
        case .cleanup: "Remove old downloads, locks, and outdated versions."
        case .autoremoveDryRun: "Preview dependencies no longer needed."
        case .autoremove: "Remove dependencies no longer needed."
        case .upgradeAll: "Upgrade every outdated formula and cask."
        case .bundleDump: "Write the current installed state to a Brewfile."
        case .bundleCheck: "Check whether the Brewfile dependencies are installed."
        }
    }
}
