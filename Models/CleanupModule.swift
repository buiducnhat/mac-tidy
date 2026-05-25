import Foundation

public enum CleanupModule: String, CaseIterable, Identifiable {
    case clean
    case purge
    case installers

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .clean: "Clean"
        case .purge: "Purge"
        case .installers: "Installers"
        }
    }
}
