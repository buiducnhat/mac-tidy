import Foundation

public enum CleanupPolicy: String, CaseIterable, Identifiable {
    case scanOnly
    case reviewRequired
    case trashAllowed
    case blocked

    public var id: String { rawValue }
}
