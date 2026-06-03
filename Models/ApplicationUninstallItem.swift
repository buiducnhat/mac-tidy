import Foundation

public struct ApplicationUninstallItem: Identifiable, Hashable {
    public enum Kind: String, CaseIterable, Identifiable {
        case appBundle
        case relatedData

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .appBundle: "App Bundle"
            case .relatedData: "Related Data"
            }
        }
    }

    public let id: String
    public let url: URL
    public let name: String
    public let size: Int64
    public let kind: Kind
    public let risk: RiskLevel
    public let cleanupPolicy: CleanupPolicy
    public let isSelectedByDefault: Bool

    public init(
        url: URL,
        name: String? = nil,
        size: Int64,
        kind: Kind,
        risk: RiskLevel,
        cleanupPolicy: CleanupPolicy,
        isSelectedByDefault: Bool
    ) {
        let standardizedURL = url.standardizedFileURL
        self.id = standardizedURL.path
        self.url = standardizedURL
        self.name = name ?? (standardizedURL.lastPathComponent.isEmpty ? standardizedURL.path : standardizedURL.lastPathComponent)
        self.size = size
        self.kind = kind
        self.risk = risk
        self.cleanupPolicy = cleanupPolicy
        self.isSelectedByDefault = isSelectedByDefault
    }
}
