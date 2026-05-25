import Foundation

public enum ScanCategory: String, CaseIterable, Identifiable {
    case folder
    case file
    case cache
    case projectArtifact
    case installer
    case protected
    case unknown

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .folder: "Folder"
        case .file: "File"
        case .cache: "Cache"
        case .projectArtifact: "Project"
        case .installer: "Installer"
        case .protected: "Protected"
        case .unknown: "Unknown"
        }
    }
}
