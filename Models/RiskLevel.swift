import Foundation

public enum RiskLevel: String, CaseIterable, Identifiable, Comparable {
    case low
    case review
    case high
    case blocked

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .low: "Low"
        case .review: "Review"
        case .high: "High"
        case .blocked: "Blocked"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .low: 0
        case .review: 1
        case .high: 2
        case .blocked: 3
        }
    }

    public static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
